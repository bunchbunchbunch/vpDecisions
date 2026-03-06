"""Step 1: Scrape region pages to build casino list."""
from __future__ import annotations

import re
import time
import logging
from bs4 import BeautifulSoup
import requests

from config import BASE_URL, REQUEST_DELAY
from models import Casino

logger = logging.getLogger(__name__)


def scrape_region(session: requests.Session, region: str) -> list[Casino]:
    """Parse a single region page and return list of Casino objects."""
    url = f"{BASE_URL}/casinos/by-region/{region}"
    logger.info(f"Scraping region: {region} ({url})")

    resp = session.get(url, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "html.parser")

    casinos = []

    # Find the region container div (id like "region_X")
    region_div = soup.find("div", id=re.compile(r"^region_\d+"))
    if not region_div:
        logger.warning(f"No region div found for {region}")
        return casinos

    # Each casino has two sibling divs:
    # 1) A div with casino info (name link, rating img, location text, coupon)
    # 2) A div with class "casino-games_summary" containing <code> with game summaries

    # Find all casino link anchors within the region div
    casino_links = region_div.find_all("a", href=re.compile(r"^/casino/"))

    for link in casino_links:
        slug = link["href"].replace("/casino/", "")
        name = link.get_text(strip=True)

        # The parent div contains rating, location, coupon info
        info_div = link.find_parent("div", style=re.compile(r"float:left"))
        if not info_div:
            info_div = link.parent

        # Rating: look for img with alt containing "Stars" or "Star"
        rating = None
        rating_img = info_div.find("img", alt=re.compile(r"Star", re.I))
        if rating_img:
            alt_text = rating_img.get("alt", "")
            match = re.search(r"([\d.]+)\s*(?:Stars?|/)", alt_text)
            if match:
                rating = float(match.group(1))

        # Location: text content after the link/rating, before coupon
        # Get all text in the info div and extract location
        location = ""
        for text_node in info_div.stripped_strings:
            if text_node == name:
                continue
            if "Coupon" in text_node:
                continue
            if re.match(r"[\d.]+\s*Star", text_node):
                continue
            # This should be the location like "Laughlin, NV"
            text_node = text_node.strip()
            if text_node and re.search(r"[A-Z]{2}$|[A-Za-z]+$", text_node):
                location = text_node
                break

        # Coupon
        has_coupon = bool(info_div.find("i", string=re.compile(r"Coupon")))

        # Closed status: check the next sibling code block
        is_closed = False
        # Navigate up to the pure-u-1 parent, then find the next sibling with casino-games_summary
        casino_info_parent = link.find_parent("div", class_="pure-u-1")
        if casino_info_parent:
            summary_div = casino_info_parent.find_next_sibling(
                "div", class_=re.compile(r"casino-games_summary")
            )
            if summary_div:
                code = summary_div.find("code")
                if code and "Closed" in code.get_text():
                    is_closed = True

        casino = Casino(
            slug=slug,
            name=name,
            region=region,
            location=location,
            rating=rating,
            is_closed=is_closed,
            has_coupon=has_coupon,
            source_url=f"{BASE_URL}/casino/{slug}",
        )
        casinos.append(casino)
        logger.debug(f"  Found casino: {name} ({'CLOSED' if is_closed else 'open'})")

    logger.info(f"  Found {len(casinos)} casinos in {region}")
    return casinos


def scrape_all_regions(
    session: requests.Session, regions: list[str] | None = None
) -> list[Casino]:
    """Scrape all region pages and return combined casino list."""
    from config import REGIONS

    if regions is None:
        regions = REGIONS

    all_casinos = []
    for i, region in enumerate(regions):
        try:
            casinos = scrape_region(session, region)
            all_casinos.extend(casinos)
        except Exception as e:
            logger.error(f"Failed to scrape region {region}: {e}")

        if i < len(regions) - 1:
            time.sleep(REQUEST_DELAY)

    logger.info(f"Total casinos found: {len(all_casinos)}")
    return all_casinos
