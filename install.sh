#!/bin/bash

# Build the project
cargo build --release || exit 1

# Default directories
DEFAULT_ROOT="$HOME/vuv"
DEFAULT_VUV_DIR="$DEFAULT_ROOT/bin"
DEFAULT_VUV_CONFIG="$DEFAULT_ROOT/config"
DEFAULT_VENV_DIR="$DEFAULT_ROOT/venvs"

# Allow customization through environment variables
VUV_ROOT="${VUV_ROOT_DIR:-$DEFAULT_ROOT}"
VUV_DIR="${VUV_CONFIG_DIR:-$DEFAULT_VUV_DIR}"
VUV_CONFIG="${VUV_CONFIG:-$DEFAULT_VUV_CONFIG}"
VENV_DIR="${VUV_VENV_DIR:-$DEFAULT_VENV_DIR}"

echo "Configuration:"
echo "  VUV_ROOT_DIR   = $VUV_ROOT"
echo "  VUV_DIR        = $VUV_DIR"
echo "  VUV_CONFIG     = $VUV_CONFIG"
echo "  VUV_VENV_DIR   = $VENV_DIR"
echo
echo "To customize these locations, set these environment variables before installation:"
echo "  VUV_ROOT_DIR   - Root directory for all vuv related files"
echo "  VUV_DIR        - Directory for executable files"
echo "  VUV_CONFIG     - Directory for configuration files"
echo "  VUV_VENV_DIR   - Directory for virtual environments"

# Setup shell integration
echo "Please select your shell:"
echo "1) bash"
echo "2) zsh"
read -p "Enter the number corresponding to your shell: " shell_choice


# Create directories if they don't exist
mkdir -p "$VUV_DIR"
mkdir -p "$VUV_CONFIG"
mkdir -p "$VENV_DIR"

# Copy the binary
cp target/release/vuv-rs "$VUV_DIR/vuv-bin"

# Make it executable
chmod +x "$VUV_DIR/vuv-bin"

SHELL_RC=""
case $shell_choice in
    1)
        SHELL_RC="$HOME/.bashrc"
        ;;
    2)
        SHELL_RC="$HOME/.zshrc"
        ;;
    *)
        echo "Invalid choice. Installation incomplete."
        exit 1
        ;;
esac

# Create the shell function wrapper
cat << EOF > "$VUV_DIR/vuv.sh"
# vuv configuration
export VUV_ROOT_DIR="$VUV_ROOT"
export VUV_CONFIG_DIR="$VUV_CONFIG"
export VUV_CONFIG="$VUV_CONFIG"
export VUV_VENV_DIR="$VENV_DIR"

function vuv() {
    case "\$1" in
        "activate")
            if [ -z "\$2" ]; then
                echo "Usage: vuv activate <environment_name>" >&2
                return 1
            fi
            local venv_path="\$VUV_VENV_DIR/\$2"
            if [ ! -d "\$venv_path" ]; then
                echo "Virtual environment \$2 does not exist" >&2
                return 1
            fi
            if [ -f "\$venv_path/bin/activate" ]; then
                source "\$venv_path/bin/activate"
            elif [ -f "\$venv_path/Scripts/activate" ]; then
                source "\$venv_path/Scripts/activate"
            else
                echo "Error: Activation script not found" >&2
                return 1
            fi
            ;;
        "deactivate")
            if [ -z "\$VIRTUAL_ENV" ]; then
                echo "No virtual environment is currently activated" >&2
                return 1
            fi
            deactivate
            ;;
        *)
            vuv-bin "\$@"
            ;;
    esac
}

# Add completion for vuv commands
_vuv_complete() {
    local cur=\${COMP_WORDS[COMP_CWORD]}
    local prev=\${COMP_WORDS[COMP_CWORD-1]}
    
    if [ "\$prev" = "activate" ]; then
        local venvs=\$(ls "\$VUV_VENV_DIR" 2>/dev/null)
        COMPREPLY=(\$(compgen -W "\$venvs" -- "\$cur"))
    elif [ "\$COMP_CWORD" = 1 ]; then
        COMPREPLY=(\$(compgen -W "activate deactivate create remove list install uninstall config" -- "\$cur"))
    fi
}

complete -F _vuv_complete vuv
EOF

# Add to PATH if not already there
if ! grep -q "$VUV_DIR" "$SHELL_RC"; then
    echo "export PATH=\"\$PATH:$VUV_DIR\"" >> "$SHELL_RC"
fi

# Source the shell function
if ! grep -q "source \"$VUV_DIR/vuv.sh\"" "$SHELL_RC"; then
    echo "source \"$VUV_DIR/vuv.sh\"" >> "$SHELL_RC"
fi

echo "Installation complete!"

echo
echo "Please restart your shell or run:"
echo "source $SHELL_RC" 