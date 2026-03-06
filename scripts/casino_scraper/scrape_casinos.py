"""Step 2: Scrape individual casino pages for game/config details."""
from __future__ import annotations

import re
import time
import logging
from bs4 import BeautifulSoup, Tag
import requests

from config import BASE_URL, REQUEST_DELAY
from models import Casino, Game, GameConfig

logger = logging.getLogger(__name__)


def parse_casino_page(html: str, casino: Casino) -> tuple[list[Game], list[GameConfig]]:
    """Parse a casino detail page and extract games and configurations."""
    soup = BeautifulSoup(html, "html.parser")
    games = []
    configs = []

    # Get game count from "X VP Games:" text
    game_count_div = soup.find("div", string=re.compile(r"\d+\s+VP\s+Games?:"))
    if game_count_div:
        match = re.search(r"(\d+)\s+VP\s+Games?:", game_count_div.get_text())
        if match:
            casino.game_count = int(match.group(1))

    # Find all game header rows (grey background divs with return % and game name)
    game_headers = soup.find_all(
        "div",
        class_="pure-g",
        style=re.compile(r"background-color:#ccc"),
    )

    for header in game_headers:
        # Extract return % and abbreviation from <code>
        code_elem = header.find("code")
        if not code_elem:
            continue

        code_text = code_elem.get_text(strip=True)
        pct_match = re.match(r"([\d.]+)%\s+(.+)", code_text)
        if not pct_match:
            continue

        return_pct = float(pct_match.group(1))
        abbreviation = pct_match.group(2).strip()

        # Extract full game name from bold span
        name_span = header.find("span", style=re.compile(r"font-weight:bolder"))
        game_name = name_span.get_text(strip=True) if name_span else abbreviation

        # Extract pay table from the last column div
        # The pay table is in the div with class containing p1r-box within the header
        pay_table = ""
        divs = header.find_all("div", class_=re.compile(r"pure-u-"))
        for div in divs:
            text = div.get_text(strip=True)
            if re.match(r"^\d+(-\d+)+$", text):
                pay_table = text
                break

        game = Game(
            game_name=game_name,
            abbreviation=abbreviation,
            pay_table=pay_table,
            return_pct=return_pct,
        )
        games.append(game)

        # Now find all config rows that follow this header
        # Config rows are sibling divs with class "pure-g p1l-box p1r-box smaller"
        sibling = header.find_next_sibling()
        while sibling:
            if not isinstance(sibling, Tag):
                sibling = sibling.find_next_sibling()
                continue

            # Stop if we hit another game header or a non-config element
            classes = sibling.get("class", [])
            style = sibling.get("style", "")

            # Another game header
            if "background-color:#ccc" in style:
                break

            # Ad div or other non-config content
            if "p1l-box" not in classes or "smaller" not in classes:
                # Could be an ad div - skip it and continue
                if "in-feed" in " ".join(classes) or sibling.find("ins", class_="adsbygoogle"):
                    sibling = sibling.find_next_sibling()
                    continue
                # Could be a spacer/ad container
                if "p1-box" in classes and "p1l-box" not in classes:
                    sibling = sibling.find_next_sibling()
                    continue
                break

            # This is a config row - parse it
            config_divs = sibling.find_all("div", class_=re.compile(r"pure-u-"), recursive=False)

            denominations = ""
            play_lines = ""
            machine_type = ""
            location_in_casino = ""
            quantity_text = ""

            if len(config_divs) >= 6:
                # Col 0: denomination (pure-u-7-24 / pure-u-md-3-24)
                denominations = config_divs[0].get_text(strip=True)

                # Col 1: empty or notes (pure-u-2-24 / pure-u-md-2-24)
                # Col 2: play lines (pure-u-4-24 / pure-u-md-2-24)
                play_text = config_divs[2].get_text(strip=True)
                play_lines = play_text.replace("Play", "").strip()

                # Col 3: machine type like "Prog", "MG" (pure-u-3-24 / pure-u-md-2-24)
                machine_type = config_divs[3].get_text(strip=True)

                # Col 4: sometimes has "MG" too (pure-u-1-24 / pure-u-md-1-24)
                col4_text = config_divs[4].get_text(strip=True)
                if col4_text and not machine_type:
                    machine_type = col4_text
                elif col4_text and machine_type:
                    machine_type = f"{machine_type} {col4_text}".strip()
                # If machine_type is empty but col4 has content, use col4
                if not machine_type and col4_text:
                    machine_type = col4_text

                # Col 5: location (pure-u-1 / pure-u-md-6-24) - contains <a> tag
                loc_link = config_divs[5].find("a")
                if loc_link:
                    location_in_casino = loc_link.get_text(strip=True)
                else:
                    location_in_casino = config_divs[5].get_text(strip=True)

                # Col 6: quantity + physical type (pure-u-2-5 / pure-u-md-3-24)
                if len(config_divs) >= 7:
                    quantity_text = config_divs[6].get_text(strip=True)

            # Parse quantity into number and physical type
            quantity = ""
            physical_type = ""
            if quantity_text:
                qty_match = re.match(r"(\d+)\s*(.*)", quantity_text)
                if qty_match:
                    quantity = qty_match.group(1)
                    physical_type = qty_match.group(2).strip()

            config = GameConfig(
                casino_slug=casino.slug,
                abbreviation=abbreviation,
                pay_table=pay_table,
                denominations=denominations,
                play_lines=play_lines,
                machine_type=machine_type,
                physical_type=physical_type,
                location_in_casino=location_in_casino,
                quantity=quantity,
            )
            configs.append(config)

            sibling = sibling.find_next_sibling()

    return games, configs


def scrape_casino(
    session: requests.Session, casino: Casino
) -> tuple[list[Game], list[GameConfig]]:
    """Fetch and parse a single casino's detail page."""
    url = casino.source_url
    logger.info(f"Scraping casino: {casino.name} ({url})")

    resp = session.get(url, timeout=30)
    resp.raise_for_status()

    return parse_casino_page(resp.text, casino)


def scrape_all_casinos(
    session: requests.Session, casinos: list[Casino]
) -> tuple[list[Game], list[GameConfig]]:
    """Scrape all non-closed casino pages. Returns deduplicated games and all configs."""
    all_games: dict[tuple[str, str], Game] = {}  # (abbreviation, pay_table) -> Game
    all_configs: list[GameConfig] = []

    open_casinos = [c for c in casinos if not c.is_closed]
    logger.info(
        f"Scraping {len(open_casinos)} open casinos (skipping {len(casinos) - len(open_casinos)} closed)"
    )

    for i, casino in enumerate(open_casinos):
        try:
            games, configs = scrape_casino(session, casino)
            for game in games:
                key = (game.abbreviation, game.pay_table)
                if key not in all_games:
                    all_games[key] = game
            all_configs.extend(configs)
            logger.info(
                f"  [{i+1}/{len(open_casinos)}] {casino.name}: {len(games)} games, {len(configs)} configs"
            )
        except Exception as e:
            logger.error(f"  Failed to scrape {casino.name}: {e}")

        if i < len(open_casinos) - 1:
            time.sleep(REQUEST_DELAY)

    logger.info(
        f"Total unique games: {len(all_games)}, total configs: {len(all_configs)}"
    )
    return list(all_games.values()), all_configs
