import json
import os
import sys
import time
import uuid
import traceback

# Debug log file
DEBUG_LOG = os.path.join(os.getenv('TEMP', '.'), 'obsidian_vault_register_debug.log')

def log_debug(message):
    """Write debug message to log file."""
    try:
        with open(DEBUG_LOG, 'a', encoding='utf-8') as f:
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            f.write(f"[{timestamp}] {message}\n")
    except:
        pass  # Fail silently if we can't write debug log

def get_appdata_path():
    """Returns the path to the user's AppData\Roaming directory."""
    return os.getenv('APPDATA')

def get_obsidian_json_path():
    """Returns the full path to the obsidian.json file."""
    appdata_path = get_appdata_path()
    if not appdata_path:
        raise EnvironmentError("APPDATA environment variable not found.")
    return os.path.join(appdata_path, 'Obsidian', 'obsidian.json')

def register_vault(vault_path):
    """Adds a new vault to obsidian.json if it doesn't already exist."""
    log_debug(f"=== Starting registration for: {vault_path}")

    obsidian_json_path = get_obsidian_json_path()
    log_debug(f"Obsidian JSON path: {obsidian_json_path}")

    # Ensure the Obsidian directory exists
    os.makedirs(os.path.dirname(obsidian_json_path), exist_ok=True)
    log_debug(f"Ensured directory exists: {os.path.dirname(obsidian_json_path)}")

    vault_path_normalized = os.path.abspath(vault_path)
    log_debug(f"Normalized vault path: {vault_path_normalized}")

    data = {"vaults": {}, "openSchemes": {"app": True}}
    
    if os.path.exists(obsidian_json_path):
        log_debug(f"Obsidian JSON exists, reading...")
        try:
            with open(obsidian_json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            log_debug(f"Successfully read obsidian.json")
        except json.JSONDecodeError as e:
            log_debug(f"JSON decode error: {e}")
            print(f"Warning: Could not decode existing obsidian.json. Creating new one.")
            # If corrupted, start with an empty structure
            data = {"vaults": {}, "openSchemes": {"app": True}}
    else:
        log_debug(f"Obsidian JSON does not exist, will create new one")

    vaults = data.get("vaults", {})
    log_debug(f"Existing vaults count: {len(vaults)}")

    # Check if the vault already exists by path
    for vault_id, vault_info in vaults.items():
        existing_path = os.path.abspath(vault_info.get("path", ""))
        log_debug(f"Checking vault {vault_id}: {existing_path}")
        if existing_path == vault_path_normalized:
            log_debug(f"Found existing vault with ID: {vault_id}")
            print(f"VAULT_ID:{vault_id}")
            return vault_id
            
    # If not found, add it
    log_debug("Vault not found, creating new entry")
    new_vault_id = uuid.uuid4().hex
    # Ensure the ID is exactly 16 hex chars as Obsidian uses
    while len(new_vault_id) < 16:
        new_vault_id += '0' # Pad with '0' if UUID.hex is less than 16 (unlikely but safe)
    new_vault_id = new_vault_id[:16] # Take first 16 chars
    log_debug(f"Generated vault ID: {new_vault_id}")

    vaults[new_vault_id] = {
        "path": vault_path_normalized,
        "ts": int(time.time() * 1000)
    }
    log_debug(f"Added vault to vaults dictionary")

    data["vaults"] = vaults

    try:
        with open(obsidian_json_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        log_debug(f"Successfully wrote to obsidian.json")
    except Exception as e:
        log_debug(f"ERROR writing to obsidian.json: {e}")
        raise

    print(f"VAULT_ID:{new_vault_id}")
    log_debug(f"Registration complete, vault ID: {new_vault_id}")
    return new_vault_id

if __name__ == "__main__":
    log_debug(f"====== Script started ======")
    log_debug(f"Arguments: {sys.argv}")
    log_debug(f"Debug log location: {DEBUG_LOG}")

    if len(sys.argv) < 2:
        log_debug("ERROR: No vault path provided")
        print("Usage: python register_obsidian_vault.py <vault_path>")
        sys.exit(1)

    vault_path = sys.argv[1]
    log_debug(f"Vault path argument: {vault_path}")

    # Ensure vault path is a directory and exists
    if not os.path.isdir(vault_path):
        log_debug(f"ERROR: Vault path is not a valid directory: {vault_path}")
        print(f"Error: Vault path '{vault_path}' is not a valid directory.")
        sys.exit(1)

    try:
        register_vault(vault_path)
        log_debug("====== Script completed successfully ======")
    except Exception as e:
        log_debug(f"EXCEPTION: {e}")
        log_debug(f"Traceback: {traceback.format_exc()}")
        print(f"An error occurred: {e}")
        sys.exit(1)
