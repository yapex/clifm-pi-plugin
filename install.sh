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

# Install fzf helper if fzf is available
if command -v fzf >/dev/null 2>&1; then
    if [ -f "$SCRIPT_DIR/ai-fzf" ]; then
        chmod +x "$SCRIPT_DIR/ai-fzf"
        # Create alias in plugins dir
        ln -sf "$SCRIPT_DIR/ai-fzf" "$PLUGINS_DIR/ai-fzf" 2>/dev/null || true
        echo -e "${GREEN}✓ FZF helper installed (use 'ai-fzf' for interactive mode)${NC}"
    fi
fi

# Install zsh completion
COMPLETION_DIR="$HOME/.zsh/completions"
if [ ! -d "$COMPLETION_DIR" ]; then
    mkdir -p "$COMPLETION_DIR"
fi

if [ -f "$SCRIPT_DIR/_ai" ]; then
    ln -sf "$SCRIPT_DIR/_ai" "$COMPLETION_DIR/_ai" 2>/dev/null || true
    echo "source $SCRIPT_DIR/_ai" >> "$HOME/.zshrc" 2>/dev/null || true
    echo -e "${GREEN}✓ Zsh completion installed${NC}"
fi

echo -e "${GREEN}✓ Plugin installed to $PLUGINS_DIR/ai${NC}"
echo ""

# Verify installation
if [ -x "$PLUGINS_DIR/ai" ]; then
    echo -e "${GREEN}✓ Installation successful!${NC}"
    echo ""
    echo "Usage:"
    echo "  ai @file1 @file2 解释这些文件"
    echo "  ai gen 查找所有 .md 文件"
    echo "  ai 解释一下什么是 bash"
    echo ""
    echo "Zsh completion enabled for @file completion"
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi
