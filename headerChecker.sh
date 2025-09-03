#!/bin/bash
# A script to crawl a website and check for the presence of key security headers

if [ -z "$1" ]; then
  echo "Usage: $0 <domain> [output_file]"
  echo "Example: $0 example.com report.txt"
  exit 1
fi

DOMAIN="$1"
OUTPUT="${2:-security_headers_report.txt}"
START_URL="https://$DOMAIN"

HEADERS=(
  "Strict-Transport-Security"
  "Content-Security-Policy"
  "X-Content-Type-Options"
  "X-Frame-Options"
  "X-XSS-Protection"
  "Referrer-Policy"
  "Permissions-Policy"
  "Cross-Origin-Resource-Policy"
  "Cross-Origin-Opener-Policy"
  "Cross-Origin-Embedder-Policy"
)

echo "Security headers for domain: $DOMAIN" > "$OUTPUT"
echo "--------------------------------------------------------------" >> "$OUTPUT"

declare -A VISITED
QUEUE=("$START_URL")

TOTAL_URLS=0
PROCESSED_URLS=0

# Rough estimate of total pages to scan
echo "Estimating total number of pages to scan..."
TMP_LINKS=$(curl -s "$START_URL" | grep -Eo 'href="([^"#]+)"' | cut -d'"' -f2 | grep -E "^/|^https://$DOMAIN" | sed "s|^/|https://$DOMAIN/|" | sed "s|//$|/|" | sort -u)
TOTAL_URLS=$((1 + $(echo "$TMP_LINKS" | wc -l)))

progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local percent=$((progress * 100 / total))
  local filled=$((progress * width / total))
  local empty=$((width - filled))
  printf "\r["
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s-" $(seq 1 $empty)
  printf "] %d%% (%d/%d)" "$percent" "$progress" "$total"
}

while [ ${#QUEUE[@]} -gt 0 ]; do
  CURRENT_URL="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")

  if [[ ${VISITED["$CURRENT_URL"]} ]]; then
    continue
  fi
  VISITED["$CURRENT_URL"]=1

  PROCESSED_URLS=$((PROCESSED_URLS + 1))
  progress_bar "$PROCESSED_URLS" "$TOTAL_URLS"

  echo -e "\nURL: $CURRENT_URL" >> "$OUTPUT"
  RESPONSE=$(curl -s -L -D - -o /dev/null "$CURRENT_URL")
  for HEADER in "${HEADERS[@]}"; do
    if echo "$RESPONSE" | grep -qi "^$HEADER:"; then
      echo "$HEADER: PRESENT" >> "$OUTPUT"
    else
      echo "$HEADER: MISSING" >> "$OUTPUT"
    fi
  done

  LINKS=$(curl -s "$CURRENT_URL" | \
    grep -Eo 'href="([^"#]+)"' | \
    cut -d'"' -f2 | \
    grep -E "^/|^https://$DOMAIN" | \
    sed "s|^/|https://$DOMAIN/|" | \
    sed "s|//$|/|" | \
    sort -u)

  for LINK in $LINKS; do
    if [[ ! ${VISITED["$LINK"]} ]]; then
      QUEUE+=("$LINK")
      TOTAL_URLS=$((TOTAL_URLS + 1))
    fi
  done
done

echo "Results saved to $OUTPUT"
echo -e "\nScan complete. Total URLs processed: $PROCESSED_URLS"
