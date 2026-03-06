#!/usr/bin/env python3
"""Casino video poker inventory scraper: scrape data and upload to Supabase."""

import argparse
import logging
import requests

from scrape_regions import scrape_all_regions
from scrape_casinos import scrape_all_casinos
from upload_to_supabase import upload

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Scrape casino video poker inventory")
    parser.add_argument(
        "--regions",
        nargs="+",
        help="Specific regions to scrape (default: all)",
    )
    parser.add_argument(
        "--scrape-only",
        action="store_true",
        help="Only scrape, don't upload to Supabase",
    )
    parser.add_argument(
        "--skip-detail",
        action="store_true",
        help="Only scrape region pages, skip individual casino pages",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable debug logging",
    )
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    session = requests.Session()
    session.headers.update(
        {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        }
    )

    # Step 1: Scrape region pages
    logger.info("=== Step 1: Scraping region pages ===")
    casinos = scrape_all_regions(session, args.regions)

    if not casinos:
        logger.error("No casinos found. Exiting.")
        return

    open_count = sum(1 for c in casinos if not c.is_closed)
    closed_count = sum(1 for c in casinos if c.is_closed)
    logger.info(f"Found {len(casinos)} casinos ({open_count} open, {closed_count} closed)")

    if args.skip_detail:
        logger.info("--skip-detail: skipping individual casino pages")
        for c in casinos:
            print(f"  {'[CLOSED] ' if c.is_closed else ''}{c.name} ({c.slug}) - {c.location} - rating={c.rating}")
        return

    # Step 2: Scrape each casino's detail page
    logger.info("=== Step 2: Scraping casino detail pages ===")
    games, configs = scrape_all_casinos(session, casinos)

    logger.info(f"\n=== Scraping complete ===")
    logger.info(f"Casinos: {len(casinos)}")
    logger.info(f"Unique games: {len(games)}")
    logger.info(f"Game configs: {len(configs)}")

    # Print a sample
    if games:
        logger.info("\nSample games:")
        for g in games[:5]:
            logger.info(f"  {g.return_pct}% {g.abbreviation} ({g.game_name}) - {g.pay_table}")

    if configs:
        logger.info("\nSample configs:")
        for c in configs[:5]:
            logger.info(
                f"  {c.casino_slug}: {c.abbreviation} {c.pay_table} - {c.denominations} ({c.quantity} {c.physical_type})"
            )

    # Step 3: Upload to Supabase
    if not args.scrape_only:
        logger.info("\n=== Step 3: Uploading to Supabase ===")
        upload(casinos, games, configs)
    else:
        logger.info("--scrape-only: skipping Supabase upload")


if __name__ == "__main__":
    main()
