#!/usr/bin/env python3
"""Build mapping between app paytable IDs and casino_games pay table strings.

Parses PayTableData.swift to extract 1-coin payouts, converts them to the
dash-separated format used in casino_games, and updates the paytable_id column.
"""
from __future__ import annotations

import re
import logging
import os
import requests

from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

PAYTABLE_SWIFT_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "..",
    "ios-native",
    "VideoPokerTrainer",
    "VideoPokerTrainer",
    "Models",
    "PayTableData.swift",
)


def parse_paytable_swift() -> dict[str, str]:
    """Parse PayTableData.swift and return {paytable_id: dash_separated_pay_table}."""
    with open(PAYTABLE_SWIFT_PATH) as f:
        content = f.read()

    mapping = {}

    # Split by case statements and process each block
    # Find all case positions
    case_starts = [(m.start(), m.group(1)) for m in re.finditer(r'case\s+"([^"]+)":', content)]

    for idx, (start, paytable_id) in enumerate(case_starts):
        # Get the block between this case and the next (or end)
        end = case_starts[idx + 1][0] if idx + 1 < len(case_starts) else len(content)
        block = content[start:end]

        # Find the return [...] block within this case
        # Need to handle nested brackets (payouts arrays inside the return array)
        return_start = block.find("return [")
        if return_start == -1:
            continue
        bracket_start = block.index("[", return_start)
        depth = 0
        bracket_end = -1
        for ci, ch in enumerate(block[bracket_start:], bracket_start):
            if ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
                if depth == 0:
                    bracket_end = ci
                    break
        if bracket_end == -1:
            continue
        rows_block = block[bracket_start + 1 : bracket_end]

        # Extract all PayTableRow payouts
        row_pattern = re.compile(r'payouts:\s*\[([^\]]+)\]')
        rows = []
        for row_match in row_pattern.finditer(rows_block):
            payouts = [int(x.strip()) for x in row_match.group(1).split(",")]
            rows.append(payouts)

        if not rows:
            continue

        # Convert to dash-separated string:
        # - Rows are top-to-bottom (Royal Flush first, lowest hand last)
        # - For Royal Flush (first row): use 5-coin value / 5
        # - For all other rows: use 1-coin value (index 0)
        # - Reverse to get bottom-to-top order
        per_coin_payouts = []
        for i, payouts in enumerate(rows):
            if i == 0:
                # Royal Flush: use max-coin payout / 5
                per_coin_payouts.append(payouts[4] // 5)
            else:
                per_coin_payouts.append(payouts[0])

        # Reverse: lowest hand first
        per_coin_payouts.reverse()
        pay_table_str = "-".join(str(p) for p in per_coin_payouts)

        mapping[paytable_id] = pay_table_str

    return mapping


def fetch_casino_games() -> list[dict]:
    """Fetch all casino_games from Supabase."""
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    }
    resp = requests.get(
        f"{SUPABASE_URL}/rest/v1/casino_games?select=id,abbreviation,pay_table,return_pct,game_name",
        headers=headers,
    )
    resp.raise_for_status()
    return resp.json()


def update_paytable_id(game_id: int, paytable_id: str):
    """Update a single casino_game's paytable_id."""
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    resp = requests.patch(
        f"{SUPABASE_URL}/rest/v1/casino_games?id=eq.{game_id}",
        json={"paytable_id": paytable_id},
        headers=headers,
    )
    resp.raise_for_status()


def main():
    # Step 1: Parse Swift file
    logger.info("Parsing PayTableData.swift...")
    app_mapping = parse_paytable_swift()
    logger.info(f"Found {len(app_mapping)} paytable definitions in app")

    # Invert: pay_table_str -> list of paytable_ids (handle collisions)
    pay_str_to_ids = {}
    for pt_id, pay_str in app_mapping.items():
        pay_str_to_ids.setdefault(pay_str, []).append(pt_id)

    collisions = {k: v for k, v in pay_str_to_ids.items() if len(v) > 1}
    if collisions:
        logger.info(f"Found {len(collisions)} pay table strings with multiple app games")

    # Map casino abbreviations to app paytable_id prefixes for disambiguation
    ABBREV_TO_FAMILY = {
        "JoB": "jacks-or-better",
        "BP": "bonus-poker-",  # trailing dash to avoid matching bonus-poker-deluxe
        "Bdlx": "bonus-poker-deluxe",
        "DB": "double-bonus-",
        "DDB": "double-double-bonus",
        "DW": "deuces-wild-",
        "DW44": "deuces-wild-44",
        "LDW": "loose-deuces",
        "AA": "all-american",
        "SA": "super-aces",
        "SDB": "super-double-bonus",
        "TDB": "triple-double-bonus",
        "TB": "triple-bonus-",
        "TB+": "triple-bonus-plus",
        "TTB": "triple-triple-bonus",
        "WHA": "white-hot-aces",
        "RAB": "royal-aces-bonus",
        "DDBAF": "ddb-aces-faces",
        "DDB+": "ddb-plus",
        "BPAF": "bonus-aces-faces",
        "DBAF": "double-bonus",  # same family, different 4K split
        "Ace$": "aces-bonus",
        "BDW": "deuces-wild",  # Bonus Deuces Wild
        "BP+": "bonus-poker-plus",
        "ToB": "tens-or-better",
        "A&8": "aces-and-eights",
        "A&F": "aces-and-faces",
        "DDJ": "double-double-jackpot",
        "DJ": "double-jackpot",
    }

    # Step 2: Fetch casino games from Supabase
    logger.info("Fetching casino_games from Supabase...")
    casino_games = fetch_casino_games()
    logger.info(f"Found {len(casino_games)} casino games")

    # Step 3: Match and update
    matched = 0
    unmatched = []
    for game in casino_games:
        pay_table = game["pay_table"]
        candidates = pay_str_to_ids.get(pay_table, [])

        paytable_id = None
        if len(candidates) == 1:
            paytable_id = candidates[0]
        elif len(candidates) > 1:
            # Disambiguate using abbreviation -> family mapping
            family_prefix = ABBREV_TO_FAMILY.get(game["abbreviation"], "")
            for candidate in candidates:
                if family_prefix and candidate.startswith(family_prefix):
                    paytable_id = candidate
                    break
            if not paytable_id:
                # Fall back to first candidate
                paytable_id = candidates[0]
                logger.warning(
                    f"  Ambiguous match for {game['abbreviation']} ({game['game_name']}): "
                    f"chose {paytable_id} from {candidates}"
                )

        if paytable_id:
            update_paytable_id(game["id"], paytable_id)
            matched += 1
            logger.info(
                f"  Matched: {game['game_name']} ({game['abbreviation']}) "
                f"{game['return_pct']}% -> {paytable_id}"
            )
        else:
            unmatched.append(game)

    logger.info(f"\n=== Results ===")
    logger.info(f"Matched: {matched}/{len(casino_games)} casino games to app strategies")
    logger.info(f"Unmatched: {len(unmatched)} games (no strategy available)")

    if unmatched:
        logger.info("\nUnmatched games:")
        for g in sorted(unmatched, key=lambda x: -float(x["return_pct"])):
            logger.info(f"  {g['return_pct']}% {g['abbreviation']} ({g['game_name']}) - {g['pay_table']}")


if __name__ == "__main__":
    main()
