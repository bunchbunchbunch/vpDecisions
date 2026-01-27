#!/usr/bin/env python3
"""
Generate manifest.json for Supabase strategy file downloads.

This script lists all .vpstrat2 files in a directory and generates a manifest.json
that can be uploaded to Supabase storage.

Usage:
    python generate_manifest.py /path/to/vpstrat2/files > manifest.json

Or if you have the files locally:
    python generate_manifest.py ../strategies/
"""

import os
import sys
import json
import re

def parse_paytable_id(filename):
    """Convert filename to paytable ID.

    Example: strategy_jacks_or_better_9_6.vpstrat2 -> jacks-or-better-9-6
    """
    # Remove strategy_ prefix and .vpstrat2 extension
    name = filename.replace("strategy_", "").replace(".vpstrat2", "")
    # Convert underscores to hyphens
    return name.replace("_", "-")

def get_game_family(paytable_id):
    """Determine the game family from the paytable ID."""
    # Order matters - check longer prefixes first
    families = [
        ("double-double-bonus", "double-double-bonus"),
        ("triple-double-bonus", "triple-double-bonus"),
        ("super-double-double-bonus", "super-double-double-bonus"),
        ("super-double-bonus", "super-double-bonus"),
        ("super-aces", "super-aces"),
        ("double-bonus", "double-bonus"),
        ("bonus-poker-deluxe", "bonus-poker-deluxe"),
        ("bonus-poker", "bonus-poker"),
        ("jacks-or-better", "jacks-or-better"),
        ("deuces-wild", "deuces-wild"),
        ("joker-poker", "joker-poker"),
        ("aces-and-faces", "aces-and-faces"),
        ("tens-or-better", "tens-or-better"),
        ("all-american", "all-american"),
    ]

    for prefix, family in families:
        if paytable_id.startswith(prefix):
            return family
    return "other"

def format_display_name(paytable_id):
    """Format a paytable ID into a readable display name."""
    # Split by hyphens
    parts = paytable_id.split("-")
    words = []
    numbers = []

    # Separate words from numbers
    i = 0
    while i < len(parts):
        part = parts[i]
        if part.isdigit():
            numbers.append(part)
        elif part in ["or", "and"]:
            words.append(part)
        elif part == "nsud":
            words.append("NSUD")
        elif part == "db":
            words.append("DB")
        elif part == "rf":
            words.append("RF")
        else:
            words.append(part.capitalize())
        i += 1

    game_name = " ".join(words)
    variant = "/".join(numbers) if numbers else ""

    if variant:
        return f"{game_name} {variant}"
    return game_name

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_manifest.py /path/to/vpstrat2/files", file=sys.stderr)
        sys.exit(1)

    directory = sys.argv[1]
    manifest = []

    # List all .vpstrat2 files
    for filename in sorted(os.listdir(directory)):
        if filename.endswith(".vpstrat2") and filename.startswith("strategy_"):
            filepath = os.path.join(directory, filename)
            file_size = os.path.getsize(filepath)

            paytable_id = parse_paytable_id(filename)
            family = get_game_family(paytable_id)
            display_name = format_display_name(paytable_id)

            manifest.append({
                "id": paytable_id,
                "name": display_name,
                "family": family,
                "fileSize": file_size
            })

    # Output as JSON
    print(json.dumps(manifest, indent=2))

if __name__ == "__main__":
    main()
