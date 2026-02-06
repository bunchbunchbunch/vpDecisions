#!/bin/bash

# Upload strategy files to Supabase Storage
# Usage: SUPABASE_SERVICE_ROLE_KEY=<key> ./upload_strategies_to_supabase.sh
#
# The service role key MUST be provided via environment variable (never as CLI argument
# to avoid exposure in shell history and process listings).
# Find your key at: Supabase Dashboard > Settings > API > service_role (secret)

set -e

SUPABASE_URL="https://ctqefgdvqiaiumtmcjdz.supabase.co"
BUCKET_NAME="strategies"
UPLOAD_DIR="$(dirname "$0")/../supabase-uploads"

# Get service role key from environment only (never accept as CLI argument for security)
SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY"

if [ -z "$SERVICE_ROLE_KEY" ]; then
    echo "Error: SUPABASE_SERVICE_ROLE_KEY environment variable required"
    echo ""
    echo "Usage: SUPABASE_SERVICE_ROLE_KEY=<key> $0"
    echo ""
    echo "Find your service role key at:"
    echo "  Supabase Dashboard > Settings > API > service_role (secret)"
    echo ""
    echo "Security note: Never pass the key as a CLI argument."
    exit 1
fi

# Check if upload directory exists
if [ ! -d "$UPLOAD_DIR" ]; then
    echo "Error: Upload directory not found: $UPLOAD_DIR"
    exit 1
fi

# Count files to upload
VPSTRAT2_FILES=$(find "$UPLOAD_DIR" -name "*.vpstrat2" -type f)
TOTAL_FILES=$(echo "$VPSTRAT2_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL_FILES .vpstrat2 files to upload"
echo "Supabase URL: $SUPABASE_URL"
echo "Bucket: $BUCKET_NAME"
echo ""

# Create bucket if it doesn't exist (ignore error if already exists)
echo "Creating bucket '$BUCKET_NAME' (if not exists)..."
curl -s -X POST "$SUPABASE_URL/storage/v1/bucket" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"$BUCKET_NAME\", \"name\": \"$BUCKET_NAME\", \"public\": true}" \
    > /dev/null 2>&1 || true

echo "Bucket ready."
echo ""

# Upload files
UPLOADED=0
FAILED=0

for FILE in $VPSTRAT2_FILES; do
    FILENAME=$(basename "$FILE")

    echo -n "Uploading $FILENAME... "

    # Upload file using Supabase Storage API
    RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/upload_response.txt \
        -X POST "$SUPABASE_URL/storage/v1/object/$BUCKET_NAME/$FILENAME" \
        -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
        -H "Content-Type: application/octet-stream" \
        -H "x-upsert: true" \
        --data-binary "@$FILE")

    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "201" ]; then
        echo "✓"
        UPLOADED=$((UPLOADED + 1))
    else
        echo "✗ (HTTP $RESPONSE)"
        cat /tmp/upload_response.txt 2>/dev/null
        echo ""
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=========================================="
echo "Upload complete!"
echo "  Uploaded: $UPLOADED"
echo "  Failed:   $FAILED"
echo "  Total:    $TOTAL_FILES"
echo ""
echo "Files are available at:"
echo "  $SUPABASE_URL/storage/v1/object/public/$BUCKET_NAME/<filename>"
