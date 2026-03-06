"""Step 3: Upload scraped data to Supabase via REST API."""

import logging
import requests as req

from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, BATCH_SIZE
from models import Casino, Game, GameConfig

logger = logging.getLogger(__name__)


def _headers():
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def _api(path: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{path}"


def _batch_insert(table: str, rows: list[dict]) -> list[dict]:
    """Insert rows in batches, return all inserted rows with IDs."""
    all_inserted = []
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        resp = req.post(_api(table), json=batch, headers=_headers())
        if resp.status_code not in (200, 201):
            logger.error(f"Insert to {table} failed: {resp.status_code} {resp.text}")
            resp.raise_for_status()
        inserted = resp.json()
        all_inserted.extend(inserted)
        logger.info(f"  Inserted {len(inserted)} rows into {table} (batch {i // BATCH_SIZE + 1})")
    return all_inserted


def truncate_tables():
    """Delete all rows from the 3 tables in reverse dependency order."""
    for table in ["casino_game_configs", "casino_games", "casinos"]:
        # Use DELETE with no filter to remove all rows
        headers = _headers()
        headers["Prefer"] = "return=minimal"
        resp = req.delete(
            _api(table) + "?id=gt.0",
            headers=headers,
        )
        if resp.status_code not in (200, 204):
            logger.error(f"Truncate {table} failed: {resp.status_code} {resp.text}")
            resp.raise_for_status()
        logger.info(f"Truncated {table}")


def upload(
    casinos: list[Casino],
    games: list[Game],
    configs: list[GameConfig],
):
    """Truncate and reload all data into Supabase."""
    if not SUPABASE_SERVICE_ROLE_KEY:
        logger.error("SUPABASE_SERVICE_ROLE_KEY not set. Skipping upload.")
        return

    logger.info("=== Starting Supabase upload ===")

    # Step 1: Truncate
    logger.info("Truncating tables...")
    truncate_tables()

    # Step 2: Insert casinos
    logger.info(f"Inserting {len(casinos)} casinos...")
    casino_rows = [
        {
            "slug": c.slug,
            "name": c.name,
            "region": c.region,
            "location": c.location,
            "rating": c.rating,
            "is_closed": c.is_closed,
            "has_coupon": c.has_coupon,
            "game_count": c.game_count,
            "source_url": c.source_url,
        }
        for c in casinos
    ]
    inserted_casinos = _batch_insert("casinos", casino_rows)

    # Build slug -> id mapping
    casino_id_map = {row["slug"]: row["id"] for row in inserted_casinos}
    logger.info(f"Casino ID map has {len(casino_id_map)} entries")

    # Step 3: Insert games
    logger.info(f"Inserting {len(games)} unique games...")
    game_rows = [
        {
            "game_name": g.game_name,
            "abbreviation": g.abbreviation,
            "pay_table": g.pay_table,
            "return_pct": g.return_pct,
        }
        for g in games
    ]
    inserted_games = _batch_insert("casino_games", game_rows)

    # Build (abbreviation, pay_table) -> id mapping
    game_id_map = {
        (row["abbreviation"], row["pay_table"]): row["id"] for row in inserted_games
    }
    logger.info(f"Game ID map has {len(game_id_map)} entries")

    # Step 4: Insert configs
    logger.info(f"Inserting {len(configs)} game configs...")
    config_rows = []
    skipped = 0
    for cfg in configs:
        casino_id = casino_id_map.get(cfg.casino_slug)
        game_id = game_id_map.get((cfg.abbreviation, cfg.pay_table))

        if not casino_id:
            logger.warning(f"No casino_id for slug: {cfg.casino_slug}")
            skipped += 1
            continue
        if not game_id:
            logger.warning(
                f"No game_id for ({cfg.abbreviation}, {cfg.pay_table}) at {cfg.casino_slug}"
            )
            skipped += 1
            continue

        config_rows.append(
            {
                "casino_id": casino_id,
                "game_id": game_id,
                "denominations": cfg.denominations,
                "play_lines": cfg.play_lines,
                "machine_type": cfg.machine_type,
                "physical_type": cfg.physical_type,
                "location_in_casino": cfg.location_in_casino,
                "quantity": cfg.quantity,
            }
        )

    if skipped:
        logger.warning(f"Skipped {skipped} configs due to missing casino/game IDs")

    _batch_insert("casino_game_configs", config_rows)

    logger.info("=== Upload complete ===")
    logger.info(
        f"Summary: {len(inserted_casinos)} casinos, {len(inserted_games)} games, {len(config_rows)} configs"
    )
