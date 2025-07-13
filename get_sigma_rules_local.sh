#!/bin/bash

SIGMA_DIR="${SIGMA_DIR:-./sigma}"
OUTPUT_FILE="sigma_rules_combined.csv"
echo "t-code,t-code name,attack tactic,sigma rule,local path,sigma rule contents" > "$OUTPUT_FILE"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 TXXXX [TYYYY ...]"
  exit 1
fi

get_tactic_from_mitre() {
  local tcode=$1
  curl -s "https://attack.mitre.org/techniques/${tcode}/" |     xmllint --html --xpath 'string(//th[contains(text(),"Tactic")]/following-sibling::td[1]//a)' - 2>/dev/null
}

for T_CODE in "$@"; do
  echo "🔍 Processing $T_CODE..."

  T_NAME=$(curl -s "https://attack.mitre.org/techniques/${T_CODE}/" | sed -n 's:.*<title>\(.*\) - Enterprise.*</title>.*:\1:p')

  if [ -z "$T_NAME" ]; then
    echo "❌ Skipping invalid T-code: $T_CODE"
    continue
  fi

  MATCHED_FILES=$(grep -ril "$T_CODE" "$SIGMA_DIR/rules" | sort -u)

  if [ -z "$MATCHED_FILES" ]; then
    echo "⚠️  No Sigma rules found for $T_CODE"
    continue
  fi

  while IFS= read -r FILE; do
    REL_PATH="${FILE#$SIGMA_DIR/}"
    RULE_NAME=$(basename "$FILE")
    TACTIC=$(get_tactic_from_mitre "$T_CODE")
    [ -z "$TACTIC" ] && TACTIC="unknown"

    CONTENT=$(< "$FILE")
    if [ -z "$CONTENT" ]; then
      CONTENT_ESCAPED="\"File empty or unreadable: $FILE\""
    else
      CONTENT_ESCAPED=$(echo "$CONTENT" | sed 's/"/""/g')
      CONTENT_ESCAPED="\"$CONTENT_ESCAPED\""
    fi

    echo "\"$T_CODE\",\"$T_NAME\",\"$TACTIC\",\"$RULE_NAME\",\"$REL_PATH\",$CONTENT_ESCAPED" >> "$OUTPUT_FILE"
  done <<< "$MATCHED_FILES"
done

echo "✅ All results saved to: $OUTPUT_FILE"
