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

echo "Full crawling and checking security headers for domain: $DOMAIN" > "$OUTPUT"
echo "--------------------------------------------------------------" >> "$OUTPUT"

declare -A VISITED
QUEUE=("$START_URL")

while [ ${#QUEUE[@]} -gt 0 ]; do
  CURRENT_URL="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")

  if [[ ${VISITED["$CURRENT_URL"]} ]]; then
    continue
  fi
  VISITED["$CURRENT_URL"]=1

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
    fi
  done
done

echo "Results saved to $OUTPUT"
