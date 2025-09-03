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

PROCESSED_URLS=0

progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local BLUE="\033[34m"
  local RESET="\033[0m"

  if [ "$total" -eq 0 ]; then
    percent=0
  else
    percent=$((progress * 100 / total))
  fi

  if [ "$progress" -gt "$total" ]; then
    percent=100
  fi

  local filled=$((percent * width / 100))
  local empty=$((width - filled))

  printf "\r["
  printf "${BLUE}"
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s-" $(seq 1 $empty)
  printf "${RESET}"
  printf "] %d%% (%d processed / %d discovered)" "$percent" "$progress" "$total"
}

while [ ${#QUEUE[@]} -gt 0 ]; do
  CURRENT_URL="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")

  if [[ ${VISITED["$CURRENT_URL"]} ]]; then
    continue
  fi

  PROCESSED_URLS=$((PROCESSED_URLS + 1))
  VISITED["$CURRENT_URL"]=1

  LINKS=$(curl -s --max-time 10 "$CURRENT_URL" | \
    grep -Eo '(href|src)="([^"#]+)"' | \
    cut -d'"' -f2 | \
    grep -E "^/|^https?://$DOMAIN|^//$DOMAIN" | \
    sed -E "s|^//|https://|" | \
    sed "s|^/|https://$DOMAIN/|" | \
    sed "s|/$||" | \
    grep -v '\.(png|jpg|jpeg|gif|css|js|ico|svg)$' | \
    sort -u) || continue

  for LINK in $LINKS; do
    if [[ ! ${VISITED["$LINK"]} ]] && [[ ! " ${QUEUE[@]} " =~ " ${LINK} " ]]; then
      QUEUE+=("$LINK")
    fi
  done

  TOTAL_DISCOVERED=$((PROCESSED_URLS + ${#QUEUE[@]}))
  progress_bar "$PROCESSED_URLS" "$TOTAL_DISCOVERED"

  echo -e "\nURL: $CURRENT_URL" >> "$OUTPUT"
  RESPONSE=$(curl -s -L --max-time 10 -D - -o /dev/null "$CURRENT_URL") || continue
  for HEADER in "${HEADERS[@]}"; do
    if echo "$RESPONSE" | grep -qi "^$HEADER:"; then
      echo "$HEADER: PRESENT" >> "$OUTPUT"
    else
      echo "$HEADER: MISSING" >> "$OUTPUT"
    fi
  done
done

echo " Results saved to $OUTPUT"
echo -e "\nScan complete. Total URLs processed: $PROCESSED_URLS"
