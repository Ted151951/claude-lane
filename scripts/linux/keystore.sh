#!/bin/bash

# Linux keystore implementation for claude-lane
# Mixed storage: keyctl (preferred) + encrypted file fallback for WSL/headless compatibility

SERVICE_NAME="claude-lane"
KEYSTORE_DIR="$HOME/.cache/claude-lane/keys"

# Ensure keystore directory exists with proper permissions
init_keystore() {
    mkdir -p "$KEYSTORE_DIR" 2>/dev/null
    chmod 700 "$KEYSTORE_DIR" 2>/dev/null
}

# Check if keyctl is available and working properly
keyctl_available() {
    # Check if keyctl command exists
    command -v keyctl >/dev/null 2>&1 || return 1
    
    # Test if keyctl actually works (not broken in WSL)
    local test_key_id
    local test_key_name="claude-lane-test-$$-$(date +%s)"
    
    # Try to add a test key
    test_key_id=$(echo "test-value" | keyctl padd user "$test_key_name" @s 2>/dev/null) || return 1
    
    # Try to read the test key
    local test_value
    test_value=$(keyctl print "$test_key_id" 2>/dev/null) || {
        keyctl revoke "$test_key_id" 2>/dev/null || true
        return 1
    }
    
    # Clean up test key
    keyctl revoke "$test_key_id" 2>/dev/null || true
    
    # Check if we got the expected value
    [[ "$test_value" == "test-value" ]] || return 1
    
    return 0
}

# Generate user-specific encryption key from system information
get_user_encryption_key() {
    local machine_id=""
    
    # Try to get machine ID from various sources
    if [[ -f /etc/machine-id ]]; then
        machine_id=$(cat /etc/machine-id 2>/dev/null)
    elif [[ -f /var/lib/dbus/machine-id ]]; then
        machine_id=$(cat /var/lib/dbus/machine-id 2>/dev/null)
    fi
    
    # Fallback to hostname if no machine-id available
    if [[ -z "$machine_id" ]]; then
        machine_id=$(hostname 2>/dev/null || echo "localhost")
    fi
    
    # Combine system-specific information for key derivation
    local key_material="${USER}:${UID}:${HOME}:$(hostname):${machine_id}:claude-lane-salt-v1"
    
    # Generate stable encryption key using SHA-256
    echo "$key_material" | sha256sum | cut -d' ' -f1
}

# Encrypt data using openssl with derived key (no password prompt)
encrypt_data() {
    local data="$1"
    local encryption_key
    encryption_key=$(get_user_encryption_key)
    
    # Use AES-256-CBC with base64 encoding
    echo "$data" | openssl enc -aes-256-cbc -a -salt -k "$encryption_key" 2>/dev/null
}

# Decrypt data using openssl with derived key
decrypt_data() {
    local encrypted_data="$1"
    local encryption_key
    encryption_key=$(get_user_encryption_key)
    
    # Decrypt using the same key
    echo "$encrypted_data" | openssl enc -aes-256-cbc -a -d -salt -k "$encryption_key" 2>/dev/null
}

# Generate file path for encrypted storage
get_key_file_path() {
    local key_ref="$1"
    init_keystore
    echo "$KEYSTORE_DIR/$(echo "$key_ref" | sha256sum | cut -d' ' -f1)"
}

set_api_key() {
    local key_ref="$1"
    local api_key="$2"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" || -z "$api_key" ]]; then
        echo "Usage: keystore.sh set <key_ref> <api_key>" >&2
        exit 1
    fi
    
    # Try keyctl first if available
    if keyctl_available; then
        # Remove existing key if it exists
        keyctl unlink %user:"$key_name" @u 2>/dev/null || true
        keyctl unlink %session:"$key_name" @s 2>/dev/null || true
        
        # Add to session keyring with proper permissions
        local key_id
        key_id=$(echo "$api_key" | keyctl padd user "$key_name" @s 2>/dev/null)
        
        if [[ -n "$key_id" ]] && keyctl setperm "$key_id" 0x3f3f0000 2>/dev/null; then
            # Link to user keyring for persistence
            keyctl link "$key_id" @u 2>/dev/null || true
            echo "Key '$key_ref' stored securely (keyctl)"
            return 0
        fi
    fi
    
    # Fallback to encrypted file storage
    local key_file
    key_file=$(get_key_file_path "$key_ref")
    local encrypted_key
    encrypted_key=$(encrypt_data "$api_key")
    
    if [[ -n "$encrypted_key" ]]; then
        echo "$encrypted_key" > "$key_file"
        chmod 600 "$key_file"
        echo "Key '$key_ref' stored securely (encrypted file)"
    else
        echo "Error: Failed to encrypt key" >&2
        exit 1
    fi
}

get_api_key() {
    local key_ref="$1"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" ]]; then
        echo "Error: key_ref is required" >&2
        exit 1
    fi
    
    # Try keyctl first if available
    if keyctl_available; then
        # Link user keyring to session for access
        keyctl link @u @s 2>/dev/null || true
        
        # Try reading from keyrings
        local key_value
        key_value=$(keyctl print %session:"$key_name" 2>/dev/null || keyctl print %user:"$key_name" 2>/dev/null)
        
        if [[ -n "$key_value" ]]; then
            echo "$key_value"
            return 0
        fi
    fi
    
    # Fallback to encrypted file storage
    local key_file
    key_file=$(get_key_file_path "$key_ref")
    
    if [[ -f "$key_file" ]]; then
        local encrypted_key
        encrypted_key=$(cat "$key_file" 2>/dev/null)
        local decrypted_key
        decrypted_key=$(decrypt_data "$encrypted_key")
        
        if [[ -n "$decrypted_key" ]]; then
            echo "$decrypted_key"
        else
            echo "Error: Failed to decrypt key '$key_ref'" >&2
            exit 1
        fi
    else
        echo "Error: Key '$key_ref' not found" >&2
        exit 1
    fi
}

delete_api_key() {
    local key_ref="$1"
    local key_name="${SERVICE_NAME}:${key_ref}"
    
    if [[ -z "$key_ref" ]]; then
        echo "Usage: keystore.sh delete <key_ref>" >&2
        exit 1
    fi
    
    local deleted=false
    
    # Try keyctl first if available
    if keyctl_available; then
        if keyctl unlink %user:"$key_name" @u 2>/dev/null || keyctl unlink %session:"$key_name" @s 2>/dev/null; then
            deleted=true
        fi
    fi
    
    # Also try encrypted file storage
    local key_file
    key_file=$(get_key_file_path "$key_ref")
    
    if [[ -f "$key_file" ]]; then
        rm -f "$key_file"
        deleted=true
    fi
    
    if [[ "$deleted" == "true" ]]; then
        echo "Key '$key_ref' deleted"
    else
        echo "Warning: Key '$key_ref' not found"
    fi
}

list_api_keys() {
    local found_keys=()
    
    # Try keyctl first if available  
    if keyctl_available; then
        # Link user keyring to session for access
        keyctl link @u @s 2>/dev/null || true
        
        # List keys from session keyring
        while IFS= read -r key_id; do
            if [[ -n "$key_id" && "$key_id" =~ ^[0-9]+$ ]]; then
                local key_desc
                key_desc=$(keyctl describe "$key_id" 2>/dev/null || true)
                if [[ "$key_desc" =~ ${SERVICE_NAME}:(.+)$ ]]; then
                    found_keys+=("${BASH_REMATCH[1]}")
                fi
            fi
        done < <(keyctl list @s 2>/dev/null || true)
        
        # Also check user keyring
        while IFS= read -r key_id; do
            if [[ -n "$key_id" && "$key_id" =~ ^[0-9]+$ ]]; then
                local key_desc
                key_desc=$(keyctl describe "$key_id" 2>/dev/null || true)
                if [[ "$key_desc" =~ ${SERVICE_NAME}:(.+)$ ]]; then
                    # Add if not already found
                    local key_name="${BASH_REMATCH[1]}"
                    local already_found=false
                    for existing_key in "${found_keys[@]}"; do
                        if [[ "$existing_key" == "$key_name" ]]; then
                            already_found=true
                            break
                        fi
                    done
                    if [[ "$already_found" == "false" ]]; then
                        found_keys+=("$key_name")
                    fi
                fi
            fi
        done < <(keyctl list @u 2>/dev/null || true)
    fi
    
    # Also check encrypted file storage
    init_keystore
    if [[ -d "$KEYSTORE_DIR" ]]; then
        # For file-based storage, we maintain a mapping file
        local mapping_file="$KEYSTORE_DIR/.key_mapping"
        
        # Check each file and try to find corresponding key names
        for key_file in "$KEYSTORE_DIR"/*; do
            if [[ -f "$key_file" && "$(basename "$key_file")" != ".key_mapping" ]]; then
                # Read mapping if it exists
                if [[ -f "$mapping_file" ]]; then
                    local file_hash
                    file_hash=$(basename "$key_file")
                    local key_name
                    key_name=$(grep "^$file_hash:" "$mapping_file" 2>/dev/null | cut -d: -f2-)
                    
                    if [[ -n "$key_name" ]]; then
                        # Check if already found in keyctl
                        local already_found=false
                        for existing_key in "${found_keys[@]}"; do
                            if [[ "$existing_key" == "$key_name" ]]; then
                                already_found=true
                                break
                            fi
                        done
                        if [[ "$already_found" == "false" ]]; then
                            found_keys+=("$key_name")
                        fi
                    fi
                fi
            fi
        done
    fi
    
    if [[ ${#found_keys[@]} -eq 0 ]]; then
        echo "No API keys stored"
    else
        printf '%s\n' "${found_keys[@]}"
    fi
}

# Update key mapping for file storage
update_key_mapping() {
    local key_ref="$1"
    local key_hash
    key_hash=$(echo "$key_ref" | sha256sum | cut -d' ' -f1)
    
    init_keystore
    local mapping_file="$KEYSTORE_DIR/.key_mapping"
    
    # Remove existing mapping for this hash
    if [[ -f "$mapping_file" ]]; then
        grep -v "^$key_hash:" "$mapping_file" > "$mapping_file.tmp" 2>/dev/null || true
        mv "$mapping_file.tmp" "$mapping_file" 2>/dev/null || true
    fi
    
    # Add new mapping
    echo "$key_hash:$key_ref" >> "$mapping_file"
    chmod 600 "$mapping_file"
}

# Main command dispatcher
case "${1:-}" in
    "set")
        set_api_key "$2" "$3"
        # Update mapping for file storage listing
        if [[ -n "$2" ]]; then
            update_key_mapping "$2"
        fi
        ;;
    "get")
        get_api_key "$2"
        ;;
    "delete")
        delete_api_key "$2"
        ;;
    "list")
        list_api_keys
        ;;
    *)
        echo "Usage: $0 {set|get|delete|list} [args...]" >&2
        echo "  set <key_ref> <api_key>  - Store an API key" >&2
        echo "  get <key_ref>            - Retrieve an API key" >&2
        echo "  delete <key_ref>         - Delete an API key" >&2
        echo "  list                     - List all stored keys" >&2
        exit 1
        ;;
esac