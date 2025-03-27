#!/bin/sh

update_input() {
# Check if there are required inputs
if [ ! -f "$1" ]; then
    echo "Error: Please enter a valid file that you want to modify."
    exit 1
fi
if [ -z "$2" ]; then
    echo "Error: Please enter a parameter name."
    exit 1
fi
if [ -z "$3" ]; then
    echo "Error: Please enter the new argument value."
    exit 1
fi

# save variables
INPUT_FILE="$1"
PARAM="$2"
NEW="$3"
TEMP_FILE=$(mktemp)

# check if parameter exists in input file
if ! grep -q "$PARAM" "$INPUT_FILE"; then
    echo "Error: $PARAM not found in $INPUT_FILE."
    exit 1
fi

if [ -z "$4" ]; then
    # if 4th argument is empty, modify existing file
    echo "Modifying existing file, $INPUT_FILE..."
    sed -E "s/(${PARAM}[[:space:]]*=[[:space:]]*)[0-9A-Za-z[:punct:]]+/\1${NEW}/" "${INPUT_FILE}" > "${TEMP_FILE}"
    mv "$TEMP_FILE" "$INPUT_FILE"
    echo "Updated $PARAM to $NEW in $INPUT_FILE."
else
    # else, create new file
    echo "Creating new file, $4..."
    sed -E "s/(${PARAM}[[:space:]]*=[[:space:]]*)[0-9A-Za-z[:punct:]]+/\1${NEW}/" "${INPUT_FILE}" > "$4"
    echo "Added $PARAM = $NEW in $4."
fi

}
