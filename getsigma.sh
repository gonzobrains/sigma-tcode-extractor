#!/bin/bash

# Usage:
#   ./get_sigma_rules_local.sh T1078 T1566
# or:
#   ./get_sigma_rules_local.sh $(cat t_codes.txt)

get_tactic_from_mitre() {
  local tcode=$1
  curl -s "https://attack.mitre.org/techniques/${tcode}/" | \
    xmllint --html --xpath 'string(//th[contains(text(),"Tactic")]/following-sibling::td[1]//a)' - 2>/dev/null
}

SIGMA_DIR="${SIGMA_DIR:-./sigma}"  # Set this to your local sigma repo if not default
OUTPUT_FILE="sigma_rules_combined.csv"
echo "t-code,t-code name,attack tactic,sigma rule,local path,sigma rule contents" > "$OUTPUT_FILE"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 TXXXX [TYYYY ...]"
  exit 1
fi

for T_CODE in "$@"; do
  echo "Processing $T_CODE..."

  # Get technique name from MITRE
  T_NAME=$(curl -s "https://attack.mitre.org/techniques/${T_CODE}/" | sed -n 's:.*<title>\(.*\) - Enterprise.*</title>.*:\1:p')

  if [ -z "$T_NAME" ]; then
    echo "Skipping invalid T-code: $T_CODE"
    continue
  fi

  # Find matching Sigma rule files (case-insensitive search)
  MATCHED_FILES=$(grep -ril "$T_CODE" "$SIGMA_DIR/rules" | sort -u)

  if [ -z "$MATCHED_FILES" ]; then
    echo "No Sigma rules found for $T_CODE"
    continue
  fi

  while IFS= read -r FILE; do
    REL_PATH="${FILE#$SIGMA_DIR/}"
    RULE_NAME=$(basename "$FILE")

    echo "processing file: $FILE"

    # Extract tactic if present
    # Try to extract tactic from MITRE website based on T-code
    TACTIC=$(get_tactic_from_mitre "$T_CODE")
    [ -z "$TACTIC" ] && TACTIC="unknown"

    # Read and escape contents
    CONTENT=$(< "$FILE")
    if [ -z "$CONTENT" ]; then
      CONTENT_ESCAPED="\"File empty or unreadable: $FILE\""
    else
      CONTENT_ESCAPED=$(echo "$CONTENT" | sed 's/"/""/g')
      CONTENT_ESCAPED="\"$CONTENT_ESCAPED\""
    fi

    # Append row to CSV
    echo "\"$T_CODE\",\"$T_NAME\",\"$TACTIC\",\"$RULE_NAME\",\"$REL_PATH\",$CONTENT_ESCAPED" >> "$OUTPUT_FILE"
  done <<< "$MATCHED_FILES"
done

echo "All results saved to: $OUTPUT_FILE"
