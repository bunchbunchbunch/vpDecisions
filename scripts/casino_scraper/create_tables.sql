-- Casino Video Poker Inventory Tables
-- Run this in Supabase Dashboard > SQL Editor

-- 1. Casinos
CREATE TABLE IF NOT EXISTS casinos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    region TEXT NOT NULL,
    location TEXT,
    rating NUMERIC(3,2),
    is_closed BOOLEAN DEFAULT false,
    has_coupon BOOLEAN DEFAULT false,
    game_count INTEGER DEFAULT 0,
    source_url TEXT,
    scraped_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Games (unique by abbreviation + pay_table)
CREATE TABLE IF NOT EXISTS casino_games (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    game_name TEXT NOT NULL,
    abbreviation TEXT NOT NULL,
    pay_table TEXT NOT NULL,
    return_pct NUMERIC(5,2),
    UNIQUE (abbreviation, pay_table)
);

-- 3. Casino-Game configurations (the join table with details)
CREATE TABLE IF NOT EXISTS casino_game_configs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    casino_id BIGINT NOT NULL REFERENCES casinos(id) ON DELETE CASCADE,
    game_id BIGINT NOT NULL REFERENCES casino_games(id) ON DELETE CASCADE,
    denominations TEXT,
    play_lines TEXT,
    machine_type TEXT,
    physical_type TEXT,
    location_in_casino TEXT,
    quantity TEXT
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_casinos_region ON casinos(region);
CREATE INDEX IF NOT EXISTS idx_casinos_slug ON casinos(slug);
CREATE INDEX IF NOT EXISTS idx_casino_game_configs_casino ON casino_game_configs(casino_id);
CREATE INDEX IF NOT EXISTS idx_casino_game_configs_game ON casino_game_configs(game_id);
CREATE INDEX IF NOT EXISTS idx_casino_games_abbrev ON casino_games(abbreviation);
