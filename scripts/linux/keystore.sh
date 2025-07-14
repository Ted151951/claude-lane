#!/bin/bash
# Linux Secret Service Key Storage for claude-lane
# Provides secure key storage using libsecret/Secret Service API

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
    echo "Requirements:"
    echo "  - libsecret-tools package must be installed"
    echo "  - A running secret service (like gnome-keyring)"
}

check_dependencies() {
    if ! command -v secret-tool >/dev/null 2>&1; then
        echo "Error: secret-tool not found. Please install libsecret-tools:" >&2
        echo "  Ubuntu/Debian: sudo apt install libsecret-tools" >&2
        echo "  Fedora/RHEL:   sudo dnf install libsecret" >&2
        echo "  Arch:          sudo pacman -S libsecret" >&2
        exit 1
    fi
}

set_api_key() {
    local key_ref="$1"
    local api_key="$2"
    
    if [[ -z "$key_ref" || -z "$api_key" ]]; then
        echo "Error: Both key_ref and api_key are required" >&2
        exit 1
    fi
    
    # Store the key using secret-tool
    echo "$api_key" | secret-tool store --label="claude-lane API key: $key_ref" \
        service "$SERVICE_NAME" \
        account "$key_ref" \
        type "api-key"
    
    echo "Key '$key_ref' stored securely"
}

get_api_key() {
    local key_ref="$1"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Retrieve the key
    secret-tool lookup service "$SERVICE_NAME" account "$key_ref" 2>/dev/null || {
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    }
}

delete_api_key() {
    local key_ref="$1"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Delete the key
    secret-tool clear service "$SERVICE_NAME" account "$key_ref" 2>/dev/null || {
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    }
    
    echo "Key '$key_ref' deleted"
}

list_api_keys() {
    echo "Stored keys:"
    
    # Search for all keys with our service name
    secret-tool search service "$SERVICE_NAME" 2>/dev/null | \
        grep "^attribute.account = " | \
        sed 's/^attribute.account = /  - /' | \
        sort || {
        echo "No keys stored"
    }
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