#!/bin/bash

# =============================================================================
# Video Poker Strategy Generator - Batch Script
# Generates VPS2 binary files for all paytables
#
# Usage:
#   ./generate_all_strategies.sh        # Interactive mode (asks for confirmation)
#   ./generate_all_strategies.sh -y     # Auto-start without confirmation
#   ./generate_all_strategies.sh --yes  # Auto-start without confirmation
# =============================================================================

set -e

# Parse arguments
AUTO_START=false
for arg in "$@"; do
    case $arg in
        -y|--yes)
            AUTO_START=true
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALCULATOR="$SCRIPT_DIR/rust_calculator/target/release/vp_calculator"
OUTPUT_DIR="$SCRIPT_DIR/../supabase-uploads"
IOS_RESOURCES="$SCRIPT_DIR/../ios-native/VideoPokerTrainer/VideoPokerTrainer/Resources"
LOG_DIR="$SCRIPT_DIR/generation_logs"
PROGRESS_FILE="$LOG_DIR/progress.txt"

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# All paytables to generate (prioritized order)
PAYTABLES=(
    # === TIER 1: Most Popular (generate first) ===
    "jacks-or-better-9-6"
    "jacks-or-better-8-5"
    "jacks-or-better-7-5"
    "jacks-or-better-6-5"
    "bonus-poker-8-5"
    "bonus-poker-7-5"
    "double-bonus-10-7"
    "double-double-bonus-9-6"
    "triple-double-bonus-9-6"
    "deuces-wild-full-pay"
    "deuces-wild-nsud"

    # === TIER 2: Common Variants ===
    "jacks-or-better-9-5"
    "jacks-or-better-8-6"
    "jacks-or-better-9-6-90"
    "jacks-or-better-9-6-940"
    "jacks-or-better-8-5-35"
    "tens-or-better-6-5"
    "bonus-poker-6-5"
    "bonus-poker-7-5-1200"
    "bonus-poker-deluxe-9-6"
    "bonus-poker-deluxe-8-6"
    "bonus-poker-deluxe-8-5"
    "bonus-poker-deluxe-7-5"
    "bonus-poker-deluxe-6-5"
    "bonus-poker-deluxe-9-5"
    "bonus-poker-deluxe-8-6-100"

    # === TIER 3: Double Bonus Family ===
    "double-bonus-10-7-100"
    "double-bonus-10-7-80"
    "double-bonus-10-6"
    "double-bonus-10-7-4"
    "double-bonus-9-7-5"
    "double-bonus-9-6-5"
    "double-bonus-9-6-4"
    "double-double-bonus-10-6-100"
    "double-double-bonus-10-6"
    "double-double-bonus-9-5"
    "double-double-bonus-8-5"
    "double-double-bonus-7-5"
    "double-double-bonus-6-5"

    # === TIER 4: Triple Bonus Family ===
    "triple-bonus-9-5"
    "triple-bonus-8-5"
    "triple-bonus-7-5"
    "triple-bonus-plus-9-5"
    "triple-bonus-plus-8-5"
    "triple-bonus-plus-7-5"
    "triple-double-bonus-9-7"
    "triple-double-bonus-8-5"
    "triple-triple-bonus-9-6"
    "triple-triple-bonus-9-5"
    "triple-triple-bonus-8-5"
    "triple-triple-bonus-7-5"

    # === TIER 5: Aces Variants ===
    "aces-and-faces-8-5"
    "aces-and-faces-7-6"
    "aces-and-faces-7-5"
    "aces-and-faces-6-5"
    "aces-and-eights-8-5"
    "aces-and-eights-7-5"
    "super-aces-8-5"
    "super-aces-7-5"
    "super-aces-6-5"
    "white-hot-aces-9-5"
    "white-hot-aces-8-5"
    "white-hot-aces-7-5"
    "white-hot-aces-6-5"
    "royal-aces-bonus-9-6"
    "royal-aces-bonus-10-5"
    "royal-aces-bonus-8-6"
    "royal-aces-bonus-9-5"
    "aces-bonus-8-5"
    "aces-bonus-7-5"
    "aces-bonus-6-5"
    "bonus-aces-faces-8-5"
    "bonus-aces-faces-7-5"
    "bonus-aces-faces-6-5"

    # === TIER 6: Super/Double Variants ===
    "super-double-bonus-9-5"
    "super-double-bonus-8-5"
    "super-double-bonus-7-5"
    "super-double-bonus-6-5"
    "double-jackpot-8-5"
    "double-jackpot-7-5"
    "double-double-jackpot-10-6"
    "double-double-jackpot-9-6"
    "ddb-aces-faces-9-6"
    "ddb-aces-faces-9-5"
    "ddb-plus-9-6"
    "ddb-plus-9-5"
    "ddb-plus-8-5"

    # === TIER 7: All American ===
    "all-american-35-8"
    "all-american-30-8"
    "all-american-25-8"
    "all-american-40-7"

    # === TIER 8: Bonus Poker Plus ===
    "bonus-poker-plus-10-7"
    "bonus-poker-plus-9-6"

    # === TIER 9: Deuces Wild Variants ===
    "deuces-wild-illinois"
    "deuces-wild-20-12-9"
    "deuces-wild-25-15-8"
    "deuces-wild-20-15-9"
    "deuces-wild-25-12-9"
    "deuces-wild-colorado"
    "deuces-wild-44-apdw"
    "deuces-wild-44-nsud"
    "deuces-wild-44-illinois"
    "loose-deuces-500-17"
    "loose-deuces-500-15"
    "loose-deuces-500-12"
    "loose-deuces-400-12"
    "double-deuces-wild-10-10"
    "double-deuces-wild-16-13"
    "double-deuces-wild-samstown"
    "double-deuces-wild-downtown"
    "double-deuces-wild-16-11"
    "double-deuces-wild-16-10"
    "triple-deuces-wild-9-6"
    "triple-deuces-wild-11-8"
    "triple-deuces-wild-10-8"
    "deluxe-deuces-wild-940"
    "deluxe-deuces-wild-800"
    "double-bonus-deuces-12"
    "double-bonus-deuces-9"
    "super-bonus-deuces-10"
    "super-bonus-deuces-9"
    "super-bonus-deuces-8"
    "deuces-joker-wild-12-9"
    "deuces-joker-wild-10-8"

    # === TIER 10: Joker Poker (53-card deck - takes longer) ===
    "joker-poker-kings-100-64"
    "joker-poker-kings-98-60"
    "joker-poker-kings-97-58"
    "joker-poker-kings-20-7"
    "joker-poker-kings-940-20"
    "joker-poker-kings-20-6"
    "joker-poker-kings-18-7"
    "joker-poker-kings-17-7"
    "joker-poker-kings-15-7"
    "joker-poker-two-pair-99-92"
    "joker-poker-two-pair-98-59"
    "joker-poker-two-pair-20-10"
    "joker-poker-two-pair-20-8"
    "joker-poker-two-pair-20-9"
    "double-joker-9-6"
    "double-joker-5-4"
    "double-joker-9-6-940"
    "double-joker-9-6-800"
    "double-joker-9-5-4"
    "double-joker-8-6-4"
    "double-joker-8-5-4"
)

# Function to check if paytable already has VPS2 file
has_vps2() {
    local paytable_id="$1"
    local filename="strategy_${paytable_id//-/_}.vpstrat2"
    [[ -f "$OUTPUT_DIR/$filename" ]] || [[ -f "$IOS_RESOURCES/$filename" ]]
}

# Function to log with timestamp
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Function to format duration
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    printf "%02d:%02d:%02d" $hours $minutes $secs
}

# Print header
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       VIDEO POKER STRATEGY GENERATOR - BATCH MODE               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Count totals
TOTAL=${#PAYTABLES[@]}
ALREADY_DONE=0
TO_GENERATE=0

for pt in "${PAYTABLES[@]}"; do
    if has_vps2 "$pt"; then
        ((ALREADY_DONE++))
    else
        ((TO_GENERATE++))
    fi
done

echo -e "Total paytables: ${YELLOW}$TOTAL${NC}"
echo -e "Already have VPS2: ${GREEN}$ALREADY_DONE${NC}"
echo -e "Need to generate: ${RED}$TO_GENERATE${NC}"
echo ""

if [[ $TO_GENERATE -eq 0 ]]; then
    echo -e "${GREEN}All paytables already have VPS2 files!${NC}"
    exit 0
fi

# Estimate time (roughly 2 hours per standard game, 3 hours for joker games)
ESTIMATED_HOURS=$((TO_GENERATE * 2))
echo -e "Estimated time: ${YELLOW}~$ESTIMATED_HOURS hours${NC} (varies by game type)"
echo ""

# Ask for confirmation (unless -y flag)
if [[ "$AUTO_START" != true ]]; then
    read -p "Start generation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Start generation
START_TIME=$(date +%s)
COMPLETED=0
FAILED=0

echo ""
log "${BLUE}Starting batch generation...${NC}"
echo ""

for i in "${!PAYTABLES[@]}"; do
    PT="${PAYTABLES[$i]}"
    INDEX=$((i + 1))

    # Skip if already done
    if has_vps2 "$PT"; then
        log "${GREEN}[$INDEX/$TOTAL] SKIP${NC} $PT (already has VPS2)"
        ((COMPLETED++))
        continue
    fi

    log "${YELLOW}[$INDEX/$TOTAL] GENERATING${NC} $PT"

    # Create log file for this paytable
    PT_LOG="$LOG_DIR/${PT}.log"
    PT_START=$(date +%s)

    # Run calculator
    if "$CALCULATOR" "$PT" --no-upload --output "$OUTPUT_DIR" > "$PT_LOG" 2>&1; then
        PT_END=$(date +%s)
        PT_DURATION=$((PT_END - PT_START))

        # Copy VPS2 to iOS Resources
        VPS2_FILE="$OUTPUT_DIR/strategy_${PT//-/_}.vpstrat2"
        if [[ -f "$VPS2_FILE" ]]; then
            cp "$VPS2_FILE" "$IOS_RESOURCES/"
            log "${GREEN}[$INDEX/$TOTAL] DONE${NC} $PT ($(format_duration $PT_DURATION))"
            ((COMPLETED++))
        else
            log "${RED}[$INDEX/$TOTAL] WARN${NC} $PT - No VPS2 file generated"
            ((FAILED++))
        fi
    else
        PT_END=$(date +%s)
        PT_DURATION=$((PT_END - PT_START))
        log "${RED}[$INDEX/$TOTAL] FAIL${NC} $PT ($(format_duration $PT_DURATION)) - see $PT_LOG"
        ((FAILED++))
    fi

    # Update progress file
    echo "Completed: $COMPLETED / $TOTAL" > "$PROGRESS_FILE"
    echo "Failed: $FAILED" >> "$PROGRESS_FILE"
    echo "Last: $PT" >> "$PROGRESS_FILE"
    echo "Time: $(date)" >> "$PROGRESS_FILE"
done

# Final summary
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    GENERATION COMPLETE                           ║${NC}"
echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  Total time: $(format_duration $TOTAL_DURATION)                                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  Completed: ${GREEN}$COMPLETED${NC}                                               ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  Failed: ${RED}$FAILED${NC}                                                  ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# List any failures
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Failed paytables:${NC}"
    for pt in "${PAYTABLES[@]}"; do
        if ! has_vps2 "$pt"; then
            echo "  - $pt"
        fi
    done
fi
