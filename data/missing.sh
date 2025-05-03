#!/bin/bash

# --- Configuration ---
CSV_FILE="$1"
TARGET_COLUMN=9 # Image_Metadata_Plate_DAPI

# --- Input Validation ---
if [ -z "$CSV_FILE" ]; then
  echo "Usage: $0 <csv_file>"
  exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

echo "Processing CSV file: $CSV_FILE"
echo "Checking for folders listed in column $TARGET_COLUMN..."
echo "----------------------------------------"

# --- Processing ---
# 1. Extract unique folder names from the target column, skipping header
#    Use awk: Set Field Separator to comma, skip first record (NR>1)
#    Print the target column ($TARGET_COLUMN)
#    Use gsub to remove potential surrounding quotes (just in case)
#    Use sort -u for unique names
unique_folders=$(awk -F',' -v col="$TARGET_COLUMN" 'NR > 1 {gsub(/^"|"$/, "", $col); print $col}' "$CSV_FILE" | sort -u)

# Check if any folders were extracted
if [ -z "$unique_folders" ]; then
  echo "No folder names found in column $TARGET_COLUMN of the CSV (or file is empty/header only)."
  exit 0
fi

# 2. Iterate through unique names and check for existence
missing_found=0
echo "Folders listed in CSV but MISSING locally:"
while IFS= read -r folder_name; do
  # Skip empty lines just in case awk produced one
  if [ -z "$folder_name" ]; then
    continue
  fi

  # Check if a directory with that name exists
  if [ ! -d "$folder_name" ]; then
    echo "- $folder_name"
    missing_found=1
  fi
done <<<"$unique_folders" # Use process substitution to feed the loop

# --- Final Report ---
if [ "$missing_found" -eq 0 ]; then
  echo "(None missing - all folders from CSV column $TARGET_COLUMN found locally)"
fi

echo "----------------------------------------"
echo "Check complete."
