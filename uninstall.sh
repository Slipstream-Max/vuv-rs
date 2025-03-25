#!/bin/bash

# Function to remove a line from a file if it exists
remove_line_from_file() {
    local pattern="$1"
    local file="$2"
    if [ -f "$file" ]; then
        sed -i "\#$pattern#d" "$file"
    fi
}

# Default directories (matching install.sh)
DEFAULT_ROOT="$HOME/vuv"
DEFAULT_VUV_DIR="$DEFAULT_ROOT/bin"
DEFAULT_VUV_CONFIG="$DEFAULT_ROOT/config"
DEFAULT_VENV_DIR="$DEFAULT_ROOT/venvs"

# Get actual directories from environment variables if set
VUV_ROOT="${VUV_ROOT_DIR:-$DEFAULT_ROOT}"
VUV_DIR="${VUV_DIR:-$DEFAULT_VUV_DIR}"
VUV_CONFIG="${VUV_CONFIG:-$DEFAULT_VUV_CONFIG}"
VENV_DIR="${VUV_VENV_DIR:-$DEFAULT_VENV_DIR}"

echo "This will uninstall vuv and remove all related files and configurations."
echo "The following directories will be removed:"
echo "  Root directory: $VUV_ROOT"
echo "  Binary directory: $VUV_DIR"
echo "  Config directory: $VUV_CONFIG"
echo "  Virtual environments: $VENV_DIR"

read -p "Do you want to keep existing virtual environments? [y/N] " keep_venvs
keep_venvs=${keep_venvs:-n}

read -p "Are you sure you want to proceed with uninstallation? [y/N] " confirm
confirm=${confirm:-n}

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Uninstallation cancelled."
    exit 1
fi

# Remove shell configuration
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        echo "Removing vuv configuration from $rc_file..."
        remove_line_from_file "source.*vuv.sh" "$rc_file"
        remove_line_from_file "export PATH=.*$VUV_DIR" "$rc_file"
        remove_line_from_file "export VUV_.*" "$rc_file"
    fi
done

# Remove program files and configurations
echo "Removing program files and configurations..."
rm -rf "$VUV_DIR"
rm -rf "$VUV_CONFIG"

# Remove virtual environments if user didn't choose to keep them
if [ "$keep_venvs" != "y" ] && [ "$keep_venvs" != "Y" ]; then
    echo "Removing virtual environments..."
    rm -rf "$VENV_DIR"
else
    echo "Keeping virtual environments in $VENV_DIR"
fi

# Remove root directory if empty
if [ -d "$VUV_ROOT" ]; then
    rmdir --ignore-fail-on-non-empty "$VUV_ROOT"
fi

echo "Uninstallation complete!"
echo "Please restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc' to apply changes."
