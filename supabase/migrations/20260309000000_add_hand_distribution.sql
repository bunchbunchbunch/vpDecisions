-- Hand distribution data: for each paytable, the probability and return
-- contribution of each hand type under optimal strategy play.

CREATE TABLE IF NOT EXISTS paytable_hand_distribution (
    paytable_id TEXT NOT NULL,
    hand_type TEXT NOT NULL,
    hand_type_order INTEGER NOT NULL,
    payout_per_coin DOUBLE PRECISION NOT NULL,
    probability DOUBLE PRECISION NOT NULL,
    return_contribution DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (paytable_id, hand_type)
);

CREATE TABLE IF NOT EXISTS paytable_returns (
    paytable_id TEXT PRIMARY KEY,
    calculated_return_pct DOUBLE PRECISION NOT NULL,
    total_canonical_hands BIGINT NOT NULL,
    total_dealt_hands BIGINT NOT NULL,
    computed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookups by paytable
CREATE INDEX IF NOT EXISTS idx_hand_distribution_paytable
    ON paytable_hand_distribution (paytable_id);

-- Enable RLS but allow service role full access
ALTER TABLE paytable_hand_distribution ENABLE ROW LEVEL SECURITY;
ALTER TABLE paytable_returns ENABLE ROW LEVEL SECURITY;

-- Public read access (this is reference data, not user-specific)
CREATE POLICY "Public read access for hand distribution"
    ON paytable_hand_distribution FOR SELECT
    USING (true);

CREATE POLICY "Public read access for paytable returns"
    ON paytable_returns FOR SELECT
    USING (true);

-- Service role can insert/update/delete
CREATE POLICY "Service role full access for hand distribution"
    ON paytable_hand_distribution FOR ALL
    USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access for paytable returns"
    ON paytable_returns FOR ALL
    USING (auth.role() = 'service_role');
