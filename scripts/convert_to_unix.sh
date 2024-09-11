#!/bin/bash
# This script needs to be run on windows prior to launching dockerfiles. 
# git bash can be opened using the search function
# once git bash is opened, you can run bash /path/to/convert_scripts.sh

# Define the directory containing the scripts
SCRIPT_DIR="C:\Users\Calvin\Documents\Software\sbm_dir\SBM\scripts"

# Loop through each file in the directory
for script in "$SCRIPT_DIR"/*.sh; do
  if [ -f "$script" ]; then
    echo "Converting $script to Unix format..."
    dos2unix "$script"
  else
    echo "No script files found in $SCRIPT_DIR"
  fi
done

echo "Conversion complete."
