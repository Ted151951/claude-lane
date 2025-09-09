#!/bin/bash
# Linux Key Storage for claude-lane using keyctl
# Provides secure key storage using Linux kernel keyring (CLI-friendly)

set -e

ACTION=""
KEY_REF=""
API_KEY=""
SERVICE_NAME="claude-lane"

show_usage() {
    echo "Usage: $0 <action> [options]"
    echo "Actions:"
    echo "  set <key_ref> <api_key>  - Store an API key securely"
    echo "  get <key_ref>            - Retrieve an API key"
    echo "  delete <key_ref>         - Delete an API key"
    echo "  list                     - List all stored keys"
    echo ""
    echo "Storage backend: Linux kernel keyring (keyctl)"
    echo "- Keys stored in memory (never written to disk)"
    echo "- Automatic cleanup on logout/reboot"
    echo "- No password required for access"
}

check_dependencies() {
    if ! command -v keyctl >/dev/null 2>&1; then
        echo "Error: keyctl not found. Please install keyutils package:" >&2
        echo "  Ubuntu/Debian: sudo apt install keyutils" >&2
        echo "  Fedora/RHEL:   sudo dnf install keyutils" >&2
        echo "  Arch:          sudo pacman -S keyutils" >&2
        echo "" >&2
        echo "The keyutils package is small (~50KB) and provides secure" >&2
        echo "in-memory key storage via the Linux kernel keyring." >&2
        exit 1
    fi
}

set_api_key() {
    local key_ref="$1"
    local api_key="$2"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" || -z "$api_key" ]]; then
        echo "Error: Both key_ref and api_key are required" >&2
        exit 1
    fi
    
    # Remove existing key if it exists (keyctl add fails if key exists)
    keyctl unlink %user:"$key_name" @u 2>/dev/null || true
    keyctl unlink %session:"$key_name" @us 2>/dev/null || true
    
    # Try to add to persistent user keyring first, fallback to session keyring
    if ! echo "$api_key" | keyctl padd user "$key_name" @u 2>/dev/null; then
        echo "$api_key" | keyctl padd user "$key_name" @us 2>/dev/null || {
            echo "Error: Failed to store key in keyring" >&2
            echo "This may happen if the keyring is not properly initialized." >&2
            echo "Try logging out and logging back in, or contact support." >&2
            exit 1
        }
        echo "Key '$key_ref' stored securely (session keyring)"
    else
        echo "Key '$key_ref' stored securely (user keyring)"
    fi
}

get_api_key() {
    local key_ref="$1"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Try user keyring first, then session keyring
    keyctl pipe %user:"$key_name" 2>/dev/null || \
    keyctl pipe %session:"$key_name" 2>/dev/null || {
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    }
}

delete_api_key() {
    local key_ref="$1"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Try both keyrings
    local found=false
    if keyctl unlink %user:"$key_name" @u 2>/dev/null; then
        found=true
    fi
    if keyctl unlink %session:"$key_name" @us 2>/dev/null; then
        found=true
    fi
    
    if [[ "$found" != "true" ]]; then
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    fi
    
    echo "Key '$key_ref' deleted"
}

list_api_keys() {
    echo "Stored keys:"
    
    # Function to extract and display key names
    list_from_keyring() {
        local keyring="$1"
        local keyids=$(keyctl rlist "$keyring" 2>/dev/null)
        local output=""
        
        for keyid in $keyids; do
            if [[ -n "$keyid" ]]; then
                local desc=$(keyctl rdescribe "$keyid" 2>/dev/null)
                local key_desc=$(echo "$desc" | cut -d';' -f5)
                if [[ "$key_desc" == ${SERVICE_NAME}:* ]]; then
                    local key_ref="${key_desc#${SERVICE_NAME}:}"
                    output="${output}  - $key_ref\n"
                fi
            fi
        done
        
        if [[ -n "$output" ]]; then
            echo -e "$output"
            return 0
        else
            return 1
        fi
    }
    
    # List from user keyring first
    local user_output=$(list_from_keyring @u)
    if [[ -n "$user_output" ]]; then
        echo "$user_output" | sort -u
        return
    fi
    
    # List from session keyring if user keyring had no results  
    local session_output=$(list_from_keyring @us)
    if [[ -n "$session_output" ]]; then
        echo "$session_output" | sort -u
        return
    fi
    
    echo "No keys stored"
}

# Check dependencies first
check_dependencies

# Parse command line arguments
case "$1" in
    "set")
        if [[ $# -ne 3 ]]; then
            echo "Error: 'set' requires key_ref and api_key arguments" >&2
            show_usage
            exit 1
        fi
        set_api_key "$2" "$3"
        ;;
    "get")
        if [[ $# -ne 2 ]]; then
            echo "Error: 'get' requires key_ref argument" >&2
            show_usage
            exit 1
        fi
        get_api_key "$2"
        ;;
    "delete")
        if [[ $# -ne 2 ]]; then
            echo "Error: 'delete' requires key_ref argument" >&2
            show_usage
            exit 1
        fi
        delete_api_key "$2"
        ;;
    "list")
        if [[ $# -ne 1 ]]; then
            echo "Error: 'list' takes no additional arguments" >&2
            show_usage
            exit 1
        fi
        list_api_keys
        ;;
    *)
        echo "Error: Invalid action '$1'" >&2
        show_usage
        exit 1
        ;;
esac