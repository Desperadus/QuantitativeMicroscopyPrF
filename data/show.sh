#!/bin/bash

# --- Configuration ---
# Expect the line number as the first argument
LINE_NUMBER="$1"

# Check if a line number was provided
if [ -z "$LINE_NUMBER" ]; then
  echo "Usage: $0 <line_number>"
  echo "Error: Please provide the CSV line number as the first argument."
  exit 1
fi

# Validate if the input is a positive integer (optional but good practice)
if ! [[ "$LINE_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: Line number '$LINE_NUMBER' must be a positive integer."
  exit 1
fi

# Adjust this if your ImageJ command is different
IMAGEJ_CMD="imagej"
# Or use "fiji" if you have FIJI installed and configured
# IMAGEJ_CMD="fiji"

# Define the CSV file
CSV_FILE="BBBC021_v1_image.csv"

# Define the base directory where Week1, Week2 etc. folders reside.
# Assumes you run the script from this directory. Use "." for current directory.
BASE_PATH="."

echo "Attempting to retrieve line $LINE_NUMBER from $CSV_FILE..."

# --- Get the Specific CSV Row ---
# Use command substitution $() to execute awk and capture its output
# Use -v to pass the shell variable LINE_NUMBER into awk
CSV_ROW=$(awk -v line="$LINE_NUMBER" 'NR == line' "$CSV_FILE")

# Check if awk returned anything
if [ -z "$CSV_ROW" ]; then
  echo "Error: Failed to retrieve line $LINE_NUMBER from $CSV_FILE."
  echo "       Check if the file exists and the line number is valid."
  exit 1
fi

echo "Processing CSV row: $CSV_ROW"

# --- Parse the CSV Row Efficiently ---
# Use one awk command to extract all necessary fields
# Use read to assign the space-separated output of awk to variables
read DAPI_FILENAME DAPI_PATHNAME TUBULIN_FILENAME TUBULIN_PATHNAME ACTIN_FILENAME ACTIN_PATHNAME <<<$(echo "$CSV_ROW" | awk -F',' '{
    # Remove surrounding quotes from fields 3, 4, 5, 6, 7, 8
    gsub(/^"|"$/, "", $3);
    gsub(/^"|"$/, "", $4);
    gsub(/^"|"$/, "", $5);
    gsub(/^"|"$/, "", $6);
    gsub(/^"|"$/, "", $7);
    gsub(/^"|"$/, "", $8);
    # Print the desired fields separated by spaces for 'read' command
    print $3, $4, $5, $6, $7, $8
}')

# Check if parsing resulted in empty critical fields (optional check)
if [ -z "$DAPI_FILENAME" ] || [ -z "$DAPI_PATHNAME" ]; then
  echo "Error: Failed to parse filenames/pathnames correctly from the CSV row."
  echo "       Check CSV format and field numbers (expecting data in fields 3-8)."
  exit 1
fi

# --- Construct Full Paths ---
FULL_DAPI_PATH="$BASE_PATH/$DAPI_PATHNAME/$DAPI_FILENAME"
FULL_TUBULIN_PATH="$BASE_PATH/$TUBULIN_PATHNAME/$TUBULIN_FILENAME"
FULL_ACTIN_PATH="$BASE_PATH/$ACTIN_PATHNAME/$ACTIN_FILENAME"

echo "DAPI File: $FULL_DAPI_PATH"
echo "Tubulin File: $FULL_TUBULIN_PATH"
echo "Actin File: $FULL_ACTIN_PATH"

# --- Check if files exist ---
# Using -e to check if path exists (could be file or dir, adjust if needed)
# Using -f checks specifically for a regular file
if [ ! -f "$FULL_DAPI_PATH" ]; then
  echo "Error: DAPI file not found or is not a regular file: $FULL_DAPI_PATH"
  exit 1
fi
if [ ! -f "$FULL_TUBULIN_PATH" ]; then
  echo "Error: Tubulin file not found or is not a regular file: $FULL_TUBULIN_PATH"
  exit 1
fi
if [ ! -f "$FULL_ACTIN_PATH" ]; then
  echo "Error: Actin file not found or is not a regular file: $FULL_ACTIN_PATH"
  exit 1
fi

# --- Create Temporary ImageJ Macro ---
MACRO_FILE="./temp_merge_macro_$$.ijm" # Use $$ for a more unique temp file name
echo "Generating ImageJ macro: $MACRO_FILE"

# More robust macro using getTitle() after opening
cat <<EOF >"$MACRO_FILE"
print("Opening images...");
open("$FULL_DAPI_PATH");
dapiTitle = getTitle();
open("$FULL_TUBULIN_PATH");
tubulinTitle = getTitle();
open("$FULL_ACTIN_PATH");
actinTitle = getTitle();

print("Merging channels...");
// Assign channels: c1=Red, c2=Green, c3=Blue
// Assigning Actin (window title: actinTitle) to Red (c1)
// Assigning Tubulin (window title: tubulinTitle) to Green (c2)
// Assigning DAPI (window title: dapiTitle) to Blue (c3)
run("Merge Channels...", "c1=["+actinTitle+"] c2=["+tubulinTitle+"] c3=["+dapiTitle+"] create keep");

print("Macro finished.");
// Optional: Add save command if needed
// saveAs("Tiff", "$BASE_PATH/merged_image_line_${LINE_NUMBER}.tif");
// close(); // Close the merged image window
// close(dapiTitle); close(tubulinTitle); close(actinTitle); // Close original windows
// run("Quit"); // Exit ImageJ completely
EOF

# --- Run ImageJ with the Macro ---
echo "Running ImageJ..."
# Use -macro argument for clarity, though just passing the file often works
"$IMAGEJ_CMD" "$MACRO_FILE"
# If you want ImageJ/Fiji to run headless (no GUI), add appropriate flags
# e.g., for Fiji: "$IMAGEJ_CMD" --headless --console -macro "$MACRO_FILE"

# --- Cleanup ---
echo "Cleaning up temporary macro file..."
rm "$MACRO_FILE"

echo "Script finished for line $LINE_NUMBER."
