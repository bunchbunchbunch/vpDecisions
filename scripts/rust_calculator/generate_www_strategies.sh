#!/bin/bash
# generate_www_strategies.sh — Generate WWW strategy files for all supported paytables

set -e
cd "$(dirname "$0")"

# Base paytable IDs that support WWW
PAYTABLES=(
    "jacks-or-better-9-6"
    "jacks-or-better-9-5"
    "jacks-or-better-8-6"
    "jacks-or-better-8-5"
    "jacks-or-better-7-5"
    "bonus-poker-8-5"
    "bonus-poker-7-5"
    "double-bonus-10-7"
    "double-double-bonus-10-6"
    "double-double-bonus-9-6"
    "triple-double-bonus-9-7"
    "triple-double-bonus-9-6"
    "deuces-wild-full-pay"
    "deuces-wild-nsud"
)

echo "Building calculator..."
cargo build --release

for base in "${PAYTABLES[@]}"; do
    # Skip 0w — with 0 jokers the deck is standard 52 cards and the boosted
    # pay table hands (Five of a Kind, Wild Royal) are unreachable, so EVs are
    # identical to the base strategy file. The iOS app uses the base file for 0w.
    for wilds in 1 2 3; do
        id="www-${base}-${wilds}w"
        echo "=== Generating: $id ==="
        cargo run --release -- --paytable "$id"
    done
done

echo "Done! Generated $(ls strategies/strategy_www_* 2>/dev/null | wc -l) WWW strategy files."
