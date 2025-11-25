import json
import os
import sys
import time
import uuid

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
    obsidian_json_path = get_obsidian_json_path()
    
    # Ensure the Obsidian directory exists
    os.makedirs(os.path.dirname(obsidian_json_path), exist_ok=True)

    vault_path_normalized = os.path.abspath(vault_path)

    data = {"vaults": {}, "openSchemes": {"app": True}}
    
    if os.path.exists(obsidian_json_path):
        try:
            with open(obsidian_json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except json.JSONDecodeError:
            print(f"Warning: Could not decode existing obsidian.json. Creating new one.")
            # If corrupted, start with an empty structure
            data = {"vaults": {}, "openSchemes": {"app": True}}
    
    vaults = data.get("vaults", {})
    
    # Check if the vault already exists by path
    for vault_id, vault_info in vaults.items():
        if os.path.abspath(vault_info.get("path", "")) == vault_path_normalized:
            print(f"VAULT_ID:{vault_id}")
            return vault_id
            
    # If not found, add it
    new_vault_id = uuid.uuid4().hex
    # Ensure the ID is exactly 16 hex chars as Obsidian uses
    while len(new_vault_id) < 16:
        new_vault_id += '0' # Pad with '0' if UUID.hex is less than 16 (unlikely but safe)
    new_vault_id = new_vault_id[:16] # Take first 16 chars

    vaults[new_vault_id] = {
        "path": vault_path_normalized,
        "ts": int(time.time() * 1000)
    }
    
    data["vaults"] = vaults

    with open(obsidian_json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f"VAULT_ID:{new_vault_id}")
    return new_vault_id

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python register_obsidian_vault.py <vault_path>")
        sys.exit(1)
    
    vault_path = sys.argv[1]
    
    # Ensure vault path is a directory and exists
    if not os.path.isdir(vault_path):
        print(f"Error: Vault path '{vault_path}' is not a valid directory.")
        sys.exit(1)
        
    try:
        register_vault(vault_path)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)
