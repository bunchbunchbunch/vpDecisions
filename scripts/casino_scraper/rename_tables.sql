-- Rename vpfree2 tables to generic names
-- Run this in Supabase Dashboard > SQL Editor

-- Drop old indexes first
DROP INDEX IF EXISTS idx_vpfree2_configs_game;
DROP INDEX IF EXISTS idx_vpfree2_configs_casino;
DROP INDEX IF EXISTS idx_vpfree2_casinos_slug;
DROP INDEX IF EXISTS idx_vpfree2_casinos_region;
DROP INDEX IF EXISTS idx_vpfree2_games_abbrev;

-- Rename tables (order matters for FK constraints)
ALTER TABLE vpfree2_casino_game_configs RENAME TO casino_game_configs;
ALTER TABLE vpfree2_games RENAME TO casino_games;
ALTER TABLE vpfree2_casinos RENAME TO casinos;

-- Rename vpfree2_url column
ALTER TABLE casinos RENAME COLUMN vpfree2_url TO source_url;

-- Recreate indexes with new names
CREATE INDEX IF NOT EXISTS idx_casinos_region ON casinos(region);
CREATE INDEX IF NOT EXISTS idx_casinos_slug ON casinos(slug);
CREATE INDEX IF NOT EXISTS idx_casino_games_abbrev ON casino_games(abbreviation);
CREATE INDEX IF NOT EXISTS idx_casino_game_configs_casino ON casino_game_configs(casino_id);
CREATE INDEX IF NOT EXISTS idx_casino_game_configs_game ON casino_game_configs(game_id);
