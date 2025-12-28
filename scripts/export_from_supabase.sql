-- Export 9/6 Jacks or Better strategy data from Supabase
-- Run this in Supabase SQL Editor and export as CSV

-- Simple export of all data
SELECT
    hand_key,
    best_hold,
    best_ev
FROM strategy
WHERE paytable_id = 'jacks-or-better-9-6'
ORDER BY best_ev DESC, hand_key;

-- If you want to verify counts first:
-- SELECT COUNT(*) as total_rows, COUNT(DISTINCT hand_key) as unique_hands
-- FROM strategy
-- WHERE paytable_id = 'jacks-or-better-9-6';
