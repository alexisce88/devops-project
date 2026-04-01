#!/usr/bin/env bash
# Integration tests — runs against a live environment via Nginx (port 80)
# Usage: BASE_URL=http://<staging-ip> bash integration-tests.sh

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
PASS=0
FAIL=0

green() { echo -e "\033[32m[PASS]\033[0m $1"; }
red()   { echo -e "\033[31m[FAIL]\033[0m $1"; }

check() {
  local description="$1"
  local expected="$2"
  local actual="$3"

  if echo "$actual" | grep -q "$expected"; then
    green "$description"
    PASS=$((PASS + 1))
  else
    red "$description (expected: '$expected', got: '$actual')"
    FAIL=$((FAIL + 1))
  fi
}

echo "Running integration tests against: $BASE_URL"
echo "-------------------------------------------"

# 1. Health endpoint
RESPONSE=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/health")
check "GET /health returns 200" "200" "$RESPONSE"

BODY=$(curl -sf "$BASE_URL/health")
check "GET /health body contains status ok" '"ok"' "$BODY"

# 2. Database connectivity
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/api/status")
check "GET /api/status returns 200" "200" "$HTTP_CODE"

BODY=$(curl -sf "$BASE_URL/api/status")
check "GET /api/status database is connected" "connected" "$BODY"

# 3. List items
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/api/items")
check "GET /api/items returns 200" "200" "$HTTP_CODE"

BODY=$(curl -sf "$BASE_URL/api/items")
check "GET /api/items returns a JSON array" "\[" "$BODY"

# 4. Create item
ITEM_NAME="integration-test-$(date +%s)"
BODY=$(curl -sf -X POST "$BASE_URL/api/items" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$ITEM_NAME\"}")
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/items" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"${ITEM_NAME}-2\"}")
check "POST /api/items returns 201" "201" "$HTTP_CODE"
check "POST /api/items body contains created item name" "$ITEM_NAME" "$BODY"

# 5. Reject invalid item (empty name)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/api/items" \
  -H "Content-Type: application/json" \
  -d '{"name": ""}')
check "POST /api/items with empty name returns 400" "400" "$HTTP_CODE"

# 6. Frontend is served
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$BASE_URL/")
check "GET / returns 200 (frontend served)" "200" "$HTTP_CODE"

# Summary
echo "-------------------------------------------"
echo "Results: $PASS passed, $FAIL failed"

[ "$FAIL" -eq 0 ] || exit 1
