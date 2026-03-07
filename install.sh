#!/bin/bash

# CLIFM PI Plugin Installer
# This script installs the ai plugin to clifm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}CLIFM PI Plugin Installer${NC}"
echo "================================"
echo ""

# Check dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

missing_deps=()

if ! command -v gum &> /dev/null; then
    missing_deps+=("gum")
fi

if ! command -v pi &> /dev/null; then
    missing_deps+=("pi")
fi

if ! command -v jq &> /dev/null; then
    missing_deps+=("jq")
fi

if [ ${#missing_deps[@]} -ne 0 ]; then
    echo -e "${RED}Missing dependencies:${NC}"
    for dep in "${missing_deps[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Install with:"
    echo "  brew install ${missing_deps[*]}"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies satisfied${NC}"
echo ""

# Check clifm installation
echo -e "${YELLOW}Checking clifm installation...${NC}"

if [ ! -d "$HOME/.config/clifm" ]; then
    echo -e "${RED}clifm configuration directory not found at ~/.config/clifm${NC}"
    echo "Please install clifm first: https://github.com/leo-arch/clifm"
    exit 1
fi

echo -e "${GREEN}✓ clifm is installed${NC}"
echo ""

# Create plugins directory if it doesn't exist
echo -e "${YELLOW}Installing plugin...${NC}"

PLUGINS_DIR="$HOME/.config/clifm/plugins"
mkdir -p "$PLUGINS_DIR"

# Remove old link if exists
if [ -L "$PLUGINS_DIR/ai" ] || [ -e "$PLUGINS_DIR/ai" ]; then
    echo "Removing existing plugin..."
    rm -f "$PLUGINS_DIR/ai"
fi

# Create symbolic link
ln -sf "$SCRIPT_DIR/ai" "$PLUGINS_DIR/ai"

# Make sure the script is executable
chmod +x "$SCRIPT_DIR/ai"

echo -e "${GREEN}✓ Plugin installed to $PLUGINS_DIR/ai${NC}"
echo ""

# Verify installation
if [ -x "$PLUGINS_DIR/ai" ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Usage:"
    echo "  In clifm:"
    echo "    s file1.py file2.py    # Select files"
    echo "    ai                     # Ask AI about selected files"
    echo ""
    echo "  Or:"
    echo "    ai                     # Start AI conversation"
    echo ""
    echo "  Or:"
    echo "    ai sel                 # Use CLIFM_SELFILE"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi
