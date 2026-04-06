#!/bin/bash
# generate_www_strategies.sh — Generate WWW strategy files for all supported paytables
#
# Generates strategies for every pay table in every game family that has a
# known WWW wild card distribution. Only families with confirmed distributions
# are included — no default/fallback distributions.
#
# Families with known distributions (from WildWildWildModels.swift):
#   JoB/Tens/AllAmerican    — 40% / 19% / 21% / 20%
#   Deuces Wild / Loose     — 40% / 18.3% / 21.7% / 20%
#   Bonus Poker / BP Plus   — 35.6% / 10.1% / 44.2% / 10.1%
#   Bonus Poker Deluxe      — 49% / 20.8% / 25.2% / 5%
#   Double Bonus            — 49% / 15% / 31% / 5%
#   DDB / DDB A&F / DDB+    — 49% / 22% / 24% / 5%
#   Triple Double Bonus     — 49% / 32.9% / 14.1% / 4%
#   Triple Triple Bonus     — 49% / 33.8% / 16.2% / 1%

set -e
cd "$(dirname "$0")"

# ── Configuration ─────────────────────────────────────────────────────────────

OUTPUT_DIR="../../supabase-uploads"
SKIP_EXISTING=false

for arg in "$@"; do
    case "$arg" in
        --skip-existing) SKIP_EXISTING=true ;;
        --help|-h)
            echo "Usage: $0 [--skip-existing]"
            echo "  --skip-existing  Skip strategies that already have .vpstrat2 files"
            exit 0
            ;;
    esac
done

# ── Pay table groups ──────────────────────────────────────────────────────────
# Only game families with known WWW wild card distributions are included.

# Jacks or Better family — distribution: 40/19/21/20
JACKS_OR_BETTER=(
    "jacks-or-better-6-5"
    "jacks-or-better-7-5"
    "jacks-or-better-8-5"
    "jacks-or-better-8-5-35"
    "jacks-or-better-8-6"
    "jacks-or-better-9-5"
    "jacks-or-better-9-6"
    "jacks-or-better-9-6-90"
    "jacks-or-better-9-6-940"
)

# Tens or Better family — distribution: 40/19/21/20 (same as JoB)
TENS_OR_BETTER=(
    "tens-or-better-6-5"
)

# All American family — distribution: 40/19/21/20 (same as JoB)
ALL_AMERICAN=(
    "all-american-25-8"
    "all-american-30-8"
    "all-american-35-8"
    "all-american-40-7"
)

# Bonus Poker family — distribution: 35.6/10.1/44.2/10.1
BONUS_POKER=(
    "bonus-poker-6-5"
    "bonus-poker-7-5"
    "bonus-poker-7-5-1200"
    "bonus-poker-8-5"
)

# Bonus Poker Plus family — distribution: 35.6/10.1/44.2/10.1 (same as Bonus Poker)
BONUS_POKER_PLUS=(
    "bonus-poker-plus-9-6"
    "bonus-poker-plus-10-7"
)

# Bonus Poker Deluxe family — distribution: 49/20.8/25.2/5
BONUS_POKER_DELUXE=(
    "bonus-poker-deluxe-6-5"
    "bonus-poker-deluxe-7-5"
    "bonus-poker-deluxe-8-5"
    "bonus-poker-deluxe-8-6"
    "bonus-poker-deluxe-8-6-100"
    "bonus-poker-deluxe-9-5"
    "bonus-poker-deluxe-9-6"
)

# Double Bonus family — distribution: 49/15/31/5
DOUBLE_BONUS=(
    "double-bonus-9-6-4"
    "double-bonus-9-6-5"
    "double-bonus-9-7-5"
    "double-bonus-10-6"
    "double-bonus-10-7"
    "double-bonus-10-7-4"
    "double-bonus-10-7-80"
    "double-bonus-10-7-100"
)

# Double Double Bonus family — distribution: 49/22/24/5
DOUBLE_DOUBLE_BONUS=(
    "double-double-bonus-6-5"
    "double-double-bonus-7-5"
    "double-double-bonus-8-5"
    "double-double-bonus-9-5"
    "double-double-bonus-9-6"
    "double-double-bonus-10-6"
    "double-double-bonus-10-6-100"
)

# DDB Aces & Faces family — distribution: 49/22/24/5 (same as DDB)
DDB_ACES_FACES=(
    "ddb-aces-faces-9-5"
    "ddb-aces-faces-9-6"
)

# DDB Plus family — distribution: 49/22/24/5 (same as DDB)
DDB_PLUS=(
    "ddb-plus-8-5"
    "ddb-plus-9-5"
    "ddb-plus-9-6"
)

# Triple Double Bonus family — distribution: 49/32.9/14.1/4
TRIPLE_DOUBLE_BONUS=(
    "triple-double-bonus-8-5"
    "triple-double-bonus-9-6"
    "triple-double-bonus-9-7"
)

# Triple Triple Bonus family — distribution: 49/33.8/16.2/1
TRIPLE_TRIPLE_BONUS=(
    "triple-triple-bonus-7-5"
    "triple-triple-bonus-8-5"
    "triple-triple-bonus-9-5"
    "triple-triple-bonus-9-6"
)

# Deuces Wild family — distribution: 40/18.3/21.7/20
DEUCES_WILD=(
    "deuces-wild-20-12-9"
    "deuces-wild-20-15-9"
    "deuces-wild-25-12-9"
    "deuces-wild-25-15-8"
    "deuces-wild-44-apdw"
    "deuces-wild-44-illinois"
    "deuces-wild-44-nsud"
    "deuces-wild-colorado"
    "deuces-wild-full-pay"
    "deuces-wild-illinois"
    "deuces-wild-nsud"
)

# Loose Deuces family — distribution: 40/18.3/21.7/20 (same as Deuces Wild)
LOOSE_DEUCES=(
    "loose-deuces-400-12"
    "loose-deuces-500-12"
    "loose-deuces-500-15"
    "loose-deuces-500-17"
)

# All pay tables combined (73 total)
ALL_PAYTABLES=(
    "${JACKS_OR_BETTER[@]}"
    "${TENS_OR_BETTER[@]}"
    "${ALL_AMERICAN[@]}"
    "${BONUS_POKER[@]}"
    "${BONUS_POKER_PLUS[@]}"
    "${BONUS_POKER_DELUXE[@]}"
    "${DOUBLE_BONUS[@]}"
    "${DOUBLE_DOUBLE_BONUS[@]}"
    "${DDB_ACES_FACES[@]}"
    "${DDB_PLUS[@]}"
    "${TRIPLE_DOUBLE_BONUS[@]}"
    "${TRIPLE_TRIPLE_BONUS[@]}"
    "${DEUCES_WILD[@]}"
    "${LOOSE_DEUCES[@]}"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

TOTAL_GENERATED=0
TOTAL_SKIPPED=0
TOTAL_FAILED=0
FILE_TIMES=()       # Array of elapsed seconds per strategy file
OVERALL_START=$(date +%s)

format_duration() {
    local secs=$1
    local hrs=$((secs / 3600))
    local mins=$(( (secs % 3600) / 60 ))
    local s=$((secs % 60))
    if [ "$hrs" -gt 0 ]; then
        printf "%dh %02dm %02ds" "$hrs" "$mins" "$s"
    elif [ "$mins" -gt 0 ]; then
        printf "%dm %02ds" "$mins" "$s"
    else
        printf "%ds" "$s"
    fi
}

avg_file_time() {
    local count=${#FILE_TIMES[@]}
    if [ "$count" -eq 0 ]; then echo 0; return; fi
    local sum=0
    for t in "${FILE_TIMES[@]}"; do sum=$((sum + t)); done
    echo $((sum / count))
}

print_separator() {
    echo ""
    echo "════════════════════════════════════════════════════════════════════════"
}

# ── Build ─────────────────────────────────────────────────────────────────────

echo "Building calculator (release)..."
cargo build --release 2>&1
echo ""

# ── Generate strategies for a list of paytables ───────────────────────────────

generate_group() {
    local group_name="$1"
    shift
    local paytables=("$@")
    local group_count=${#paytables[@]}
    local strategies_per_game=3  # 1w, 2w, 3w
    local total_files=$((group_count * strategies_per_game))
    local group_done=0
    local group_start=$(date +%s)

    print_separator
    echo "  $group_name"
    echo "  $group_count games × 3 wild counts = $total_files strategy files"
    print_separator
    echo ""

    for idx in "${!paytables[@]}"; do
        local base="${paytables[$idx]}"
        local game_num=$((idx + 1))
        local game_start=$(date +%s)

        echo "┌─── Game $game_num/$group_count: $base ───"
        echo "│"

        for wilds in 1 2 3; do
            local id="www-${base}-${wilds}w"
            local file_id=$(echo "$id" | tr '-' '_')
            local outfile="$OUTPUT_DIR/strategy_${file_id}.vpstrat2"

            # Skip if file exists and --skip-existing is set
            if [ "$SKIP_EXISTING" = true ] && [ -f "$outfile" ]; then
                echo "│  ⏭  ${wilds}w — already exists, skipping"
                TOTAL_SKIPPED=$((TOTAL_SKIPPED + 1))
                group_done=$((group_done + 1))
                continue
            fi

            local file_start=$(date +%s)
            echo "│  ⏳ ${wilds}w — generating $id"

            if ./target/release/vp_calculator "$id" --no-upload --output "$OUTPUT_DIR" 2>&1 | sed 's/^/│     /'; then
                local file_end=$(date +%s)
                local file_elapsed=$((file_end - file_start))
                FILE_TIMES+=("$file_elapsed")
                TOTAL_GENERATED=$((TOTAL_GENERATED + 1))
                group_done=$((group_done + 1))

                echo "│  ✅ ${wilds}w done in $(format_duration $file_elapsed)"
            else
                local file_end=$(date +%s)
                local file_elapsed=$((file_end - file_start))
                TOTAL_FAILED=$((TOTAL_FAILED + 1))
                group_done=$((group_done + 1))

                echo "│  ❌ ${wilds}w FAILED after $(format_duration $file_elapsed)"
            fi

            # Progress + ETA after each file
            local now=$(date +%s)
            local overall_elapsed=$((now - OVERALL_START))
            local overall_done=$((TOTAL_GENERATED + TOTAL_SKIPPED + TOTAL_FAILED))
            local avg=$(avg_file_time)

            if [ "$avg" -gt 0 ] && [ "$TOTAL_GENERATED" -gt 0 ]; then
                local remaining_in_group=$((total_files - group_done))
                local est_group_remaining=$((remaining_in_group * avg))

                echo "│     Avg: $(format_duration $avg)/file · Group remaining: ~$(format_duration $est_group_remaining)"
            fi
        done

        local game_end=$(date +%s)
        local game_elapsed=$((game_end - game_start))
        echo "│"
        echo "└─── $base done in $(format_duration $game_elapsed)"
        echo ""
    done

    local group_end=$(date +%s)
    local group_elapsed=$((group_end - group_start))
    echo "  $group_name complete: $(format_duration $group_elapsed)"
}

# ── Main ──────────────────────────────────────────────────────────────────────

GRAND_TOTAL=$(( ${#ALL_PAYTABLES[@]} * 3 ))

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║              WWW Strategy Generator                                ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║  Game families:        14                                          ║"
echo "║  Pay tables:           ${#ALL_PAYTABLES[@]}                                          ║"
printf "║  Strategy files:       %-3d (× 3 wild counts)                       ║\n" "$GRAND_TOTAL"
echo "║  Skip existing:        $SKIP_EXISTING                                       ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"

generate_group "All WWW Strategies (14 families, ${#ALL_PAYTABLES[@]} pay tables)" "${ALL_PAYTABLES[@]}"

# ── Summary ───────────────────────────────────────────────────────────────────

OVERALL_END=$(date +%s)
OVERALL_ELAPSED=$((OVERALL_END - OVERALL_START))

print_separator
echo "  COMPLETE"
print_separator
echo ""
echo "  Finished at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Total time:  $(format_duration $OVERALL_ELAPSED)"
echo ""
echo "  Generated:   $TOTAL_GENERATED files"
echo "  Skipped:     $TOTAL_SKIPPED files"
echo "  Failed:      $TOTAL_FAILED files"

if [ ${#FILE_TIMES[@]} -gt 0 ]; then
    echo "  Avg/file:    $(format_duration $(avg_file_time))"
fi

echo ""
echo "  Output: $OUTPUT_DIR"
echo ""
