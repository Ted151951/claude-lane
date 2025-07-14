#!/bin/bash
# macOS Keychain Key Storage for claude-lane
# Provides secure key storage using macOS Keychain Services

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
}

set_api_key() {
    local key_ref="$1"
    local api_key="$2"
    
    if [[ -z "$key_ref" || -z "$api_key" ]]; then
        echo "Error: Both key_ref and api_key are required" >&2
        exit 1
    fi
    
    # Delete existing key if it exists (security add-generic-password fails if key exists)
    security delete-generic-password -s "$SERVICE_NAME" -a "$key_ref" 2>/dev/null || true
    
    # Add the new key
    security add-generic-password -s "$SERVICE_NAME" -a "$key_ref" -w "$api_key"
    echo "Key '$key_ref' stored securely in Keychain"
}

get_api_key() {
    local key_ref="$1"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Retrieve the key
    security find-generic-password -s "$SERVICE_NAME" -a "$key_ref" -w 2>/dev/null || {
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
    
    security delete-generic-password -s "$SERVICE_NAME" -a "$key_ref" 2>/dev/null || {
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    }
    
    echo "Key '$key_ref' deleted from Keychain"
}

list_api_keys() {
    echo "Stored keys:"
    security dump-keychain | grep -A 1 -B 1 "\"$SERVICE_NAME\"" | grep '"acct"' | sed 's/.*"acct"<blob>="\([^"]*\)".*/  - \1/' | sort -u || {
        echo "No keys stored"
    }
}

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