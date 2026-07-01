#!/bin/bash

# Output file
OUTPUT_FILE="scrap-content.txt"

# Remove old content file if it exists
> "$OUTPUT_FILE"

echo "Collecting file contents into '$OUTPUT_FILE'..."

# Exclusions
EXCLUDE_PATHS=(
  "./.terraform/*"
  "./.git/*"
  "./node_modules/*"
  "./app/*"
)

EXCLUDE_FILES=(
  "scrap-content.txt"
  "scrap.sh"
  "tempt.txt"
  "collect_contents.sh"
  "deployment.md"
)

# Build find command dynamically
FIND_CMD=(find . -type f)

# Add path exclusions
for path in "${EXCLUDE_PATHS[@]}"; do
  FIND_CMD+=( ! -path "$path" )
done

# Add file exclusions
for file in "${EXCLUDE_FILES[@]}"; do
  FIND_CMD+=( ! -name "$file" )
done

# Final print
FIND_CMD+=( -print0 )

# Execute
"${FIND_CMD[@]}" | sort -z | while IFS= read -r -d '' file; do

  echo ">> Adding: $file"

  echo "===== FILE: $file =====" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  cat "$file" >> "$OUTPUT_FILE"

  echo "" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

done

echo ""
echo "Done! All contents collected into '$OUTPUT_FILE'"