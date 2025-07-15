#!/bin/bash
# claude-lane Installation Script for macOS/Linux
# Installs claude-lane with secure key storage capabilities

set -e

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.claude"
REPO_URL="https://github.com/Ted151951/claude-lane"
TEMP_DIR=$(mktemp -d)
CURRENT_VERSION="v1.2.0"
IS_UPGRADE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

check_existing_installation() {
    local installed_version=""
    
    # Check if claude-lane is already installed
    if [[ -f "$INSTALL_DIR/claude-lane" ]]; then
        print_status "Found existing claude-lane installation"
        
        # Try to get version from the installed script
        if command -v claude-lane >/dev/null 2>&1; then
            installed_version=$(claude-lane --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
        fi
        
        if [[ -n "$installed_version" ]]; then
            print_status "Currently installed version: $installed_version"
            
            if [[ "$installed_version" == "$CURRENT_VERSION" ]]; then
                print_warning "claude-lane $CURRENT_VERSION is already installed"
                echo "Re-running installation to ensure all components are up to date..."
                IS_UPGRADE=true
            elif [[ "$installed_version" < "$CURRENT_VERSION" ]]; then
                print_status "Upgrading from $installed_version to $CURRENT_VERSION"
                IS_UPGRADE=true
            else
                print_warning "Installed version ($installed_version) is newer than this installer ($CURRENT_VERSION)"
                echo "Proceeding with installation anyway..."
                IS_UPGRADE=true
            fi
        else
            print_status "Existing installation found but version could not be determined"
            print_status "Proceeding with upgrade..."
            IS_UPGRADE=true
        fi
        
        # Backup existing config if it exists and is not the template
        if [[ -f "$CONFIG_DIR/config.yaml" && "$IS_UPGRADE" == true ]]; then
            local backup_file="$CONFIG_DIR/config.yaml.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$CONFIG_DIR/config.yaml" "$backup_file"
            print_status "Backed up existing config to: $backup_file"
        fi
    else
        print_status "No existing installation found - performing fresh installation"
    fi
}

check_dependencies() {
    local platform="$1"
    
    case "$platform" in
        "macos")
            if ! command -v security >/dev/null 2>&1; then
                print_error "macOS 'security' command not found. This should be available on macOS 10.3+."
                exit 1
            fi
            ;;
        "linux")
            if ! command -v secret-tool >/dev/null 2>&1; then
                print_warning "secret-tool not found. Installing libsecret-tools..."
                
                # Try to install libsecret-tools
                if command -v apt >/dev/null 2>&1; then
                    sudo apt update && sudo apt install -y libsecret-tools
                elif command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y libsecret
                elif command -v pacman >/dev/null 2>&1; then
                    sudo pacman -S --noconfirm libsecret
                else
                    print_error "Could not install libsecret-tools automatically."
                    print_error "Please install manually:"
                    print_error "  Ubuntu/Debian: sudo apt install libsecret-tools"
                    print_error "  Fedora/RHEL:   sudo dnf install libsecret"
                    print_error "  Arch:          sudo pacman -S libsecret"
                    exit 1
                fi
            fi
            ;;
        *)
            print_error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
}

download_claude_lane() {
    print_status "Downloading claude-lane..."
    
    # Download the repository
    if command -v git >/dev/null 2>&1; then
        git clone "$REPO_URL" "$TEMP_DIR/claude-lane"
    else
        # Fallback to curl/wget
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "${REPO_URL}/archive/main.tar.gz" | tar -xz -C "$TEMP_DIR"
            mv "$TEMP_DIR/claude-lane-main" "$TEMP_DIR/claude-lane"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- "${REPO_URL}/archive/main.tar.gz" | tar -xz -C "$TEMP_DIR"
            mv "$TEMP_DIR/claude-lane-main" "$TEMP_DIR/claude-lane"
        else
            print_error "Neither git, curl, nor wget found. Cannot download claude-lane."
            exit 1
        fi
    fi
}

install_claude_lane() {
    local platform="$1"
    
    if [[ "$IS_UPGRADE" == true ]]; then
        print_status "Upgrading claude-lane..."
    else
        print_status "Installing claude-lane..."
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Copy main script
    cp "$TEMP_DIR/claude-lane/bin/claude-lane" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/claude-lane"
    
    # Copy platform-specific keystore script
    local keystore_dir="$HOME/.claude/scripts"
    mkdir -p "$keystore_dir"
    
    case "$platform" in
        "macos")
            mkdir -p "$keystore_dir/macos"
            cp "$TEMP_DIR/claude-lane/scripts/macos/keystore.sh" "$keystore_dir/macos/"
            chmod +x "$keystore_dir/macos/keystore.sh"
            ;;
        "linux")
            mkdir -p "$keystore_dir/linux"
            cp "$TEMP_DIR/claude-lane/scripts/linux/keystore.sh" "$keystore_dir/linux/"
            chmod +x "$keystore_dir/linux/keystore.sh"
            ;;
    esac
    
    # Copy templates directory for reference
    local templates_dir="$HOME/.claude/templates"
    mkdir -p "$templates_dir"
    cp "$TEMP_DIR/claude-lane/templates/config.yaml" "$templates_dir/"
    
    # Copy configuration template only if it doesn't exist (fresh install)
    if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
        cp "$TEMP_DIR/claude-lane/templates/config.yaml" "$CONFIG_DIR/"
        print_status "Created default configuration at $CONFIG_DIR/config.yaml"
    elif [[ "$IS_UPGRADE" == true ]]; then
        print_status "Preserved existing configuration at $CONFIG_DIR/config.yaml"
        print_status "Updated template available at $templates_dir/config.yaml"
    fi
}

update_path() {
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        # Determine the shell configuration file
        local shell_config=""
        case "$SHELL" in
            */bash)
                if [[ -f "$HOME/.bashrc" ]]; then
                    shell_config="$HOME/.bashrc"
                else
                    shell_config="$HOME/.bash_profile"
                fi
                ;;
            */zsh)
                shell_config="$HOME/.zshrc"
                ;;
            */fish)
                shell_config="$HOME/.config/fish/config.fish"
                mkdir -p "$(dirname "$shell_config")"
                ;;
            *)
                shell_config="$HOME/.profile"
                ;;
        esac
        
        # Add to PATH in shell config
        if [[ "$SHELL" == */fish ]]; then
            echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$shell_config"
        else
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
        fi
        
        print_success "Added $INSTALL_DIR to PATH in $shell_config"
        print_warning "Please run 'source $shell_config' or restart your terminal to use claude-lane"
    fi
}

cleanup() {
    rm -rf "$TEMP_DIR"
}

show_next_steps() {
    if [[ "$IS_UPGRADE" == true ]]; then
        print_success "claude-lane upgraded successfully to $CURRENT_VERSION!"
        echo ""
        echo "Upgrade completed:"
        echo "• Configuration preserved at $CONFIG_DIR/config.yaml"
        echo "• API keys remain securely stored"
        echo "• Updated template available at $HOME/.claude/templates/config.yaml"
        echo ""
        echo "Test your upgrade:"
        echo "  claude-lane status"
        echo "  claude-lane --version"
        echo ""
        if [[ -f "$CONFIG_DIR/config.yaml.backup."* ]]; then
            echo "Configuration backup created for safety"
        fi
        echo "For upgrade guide: https://github.com/Ted151951/claude-lane/blob/main/UPGRADE.md"
    else
        print_success "claude-lane installed successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Edit your configuration: $CONFIG_DIR/config.yaml"
        echo "2. Store your API keys:"
        echo "   claude-lane set-key official-api sk-ant-api03-..."
        echo "   claude-lane set-key proxy your-proxy-key"
        echo "3. Switch between endpoints:"
        echo "   claude-lane official-api"
        echo "   claude-lane proxy"
        echo ""
        echo "For help: claude-lane help"
    fi
    echo "Documentation: https://github.com/Ted151951/claude-lane"
}

main() {
    echo "🚀 claude-lane Installation Script"
    echo "=================================="
    
    # Check for existing installation first
    check_existing_installation
    
    # Detect platform
    local platform="$(detect_platform)"
    print_status "Detected platform: $platform"
    
    # Check dependencies
    check_dependencies "$platform"
    
    # Download and install
    download_claude_lane
    install_claude_lane "$platform"
    update_path
    
    # Cleanup
    cleanup
    
    # Show next steps
    show_next_steps
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main installation
main "$@"