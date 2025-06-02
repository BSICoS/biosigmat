#!/bin/bash

# Script to install the Git pre-push hook

# Check if .git/hooks directory exists
if [ ! -d .git/hooks ]; then
  echo "The .git/hooks directory was not found. Are you sure you are in the root of a Git repository?"
  exit 1
fi

# Copy the pre-push hook and set LF endings explicitly
tr -d '\r' < hooks/pre-push > .git/hooks/pre-push

# Make it executable
chmod +x .git/hooks/pre-push

echo "Pre-push hook installed successfully."
