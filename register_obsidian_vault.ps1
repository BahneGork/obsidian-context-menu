param(
    [Parameter(Mandatory=$true)]
    [string]$VaultPath
)

# Debug log file
$debugLog = Join-Path $env:TEMP "obsidian_vault_register_debug.log"

function Write-DebugLog {
    param([string]$Message)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "[$timestamp] $Message" | Out-File -FilePath $debugLog -Append -Encoding UTF8
    } catch {
        # Fail silently if we can't write debug log
    }
}

function Get-ObsidianJsonPath {
    $appData = [Environment]::GetFolderPath('ApplicationData')
    if (-not $appData) {
        throw "APPDATA environment variable not found."
    }
    return Join-Path $appData "Obsidian\obsidian.json"
}

function Register-Vault {
    param([string]$VaultPath)

    Write-DebugLog "=== Starting registration for: $VaultPath"

    $obsidianJsonPath = Get-ObsidianJsonPath
    Write-DebugLog "Obsidian JSON path: $obsidianJsonPath"

    # Ensure the Obsidian directory exists
    $obsidianDir = Split-Path $obsidianJsonPath
    if (-not (Test-Path $obsidianDir)) {
        New-Item -ItemType Directory -Path $obsidianDir -Force | Out-Null
        Write-DebugLog "Created directory: $obsidianDir"
    }

    # Normalize vault path
    $vaultPathNormalized = (Resolve-Path $VaultPath).Path
    Write-DebugLog "Normalized vault path: $vaultPathNormalized"

    # Initialize data structure
    $data = @{
        vaults = @{}
        openSchemes = @{ app = $true }
    }

    # Read existing obsidian.json if it exists
    if (Test-Path $obsidianJsonPath) {
        Write-DebugLog "Obsidian JSON exists, reading..."
        try {
            $jsonContent = Get-Content -Path $obsidianJsonPath -Raw -Encoding UTF8
            $data = $jsonContent | ConvertFrom-Json -AsHashtable
            Write-DebugLog "Successfully read obsidian.json"
        } catch {
            Write-DebugLog "JSON decode error: $_"
            Write-Host "Warning: Could not decode existing obsidian.json. Creating new one."
            $data = @{
                vaults = @{}
                openSchemes = @{ app = $true }
            }
        }
    } else {
        Write-DebugLog "Obsidian JSON does not exist, will create new one"
    }

    # Ensure vaults property exists
    if (-not $data.vaults) {
        $data.vaults = @{}
    }

    $vaults = $data.vaults
    Write-DebugLog "Existing vaults count: $($vaults.Count)"

    # Check if vault already exists by path
    foreach ($vaultId in $vaults.Keys) {
        $vaultInfo = $vaults[$vaultId]
        $existingPath = (Resolve-Path $vaultInfo.path -ErrorAction SilentlyContinue).Path
        Write-DebugLog "Checking vault ${vaultId}: $existingPath"

        if ($existingPath -eq $vaultPathNormalized) {
            Write-DebugLog "Found existing vault with ID: $vaultId"
            Write-Host "VAULT_ID:$vaultId"
            return $vaultId
        }
    }

    # If not found, add it
    Write-DebugLog "Vault not found, creating new entry"

    # Generate 16-character hex ID
    $guid = [System.Guid]::NewGuid().ToString("N")
    $newVaultId = $guid.Substring(0, 16)
    Write-DebugLog "Generated vault ID: $newVaultId"

    # Add new vault
    $data.vaults[$newVaultId] = @{
        path = $vaultPathNormalized
        ts = [int64](Get-Date -UFormat %s) * 1000
    }
    Write-DebugLog "Added vault to vaults dictionary"

    # Write to obsidian.json
    try {
        $jsonOutput = $data | ConvertTo-Json -Depth 10
        $jsonOutput | Out-File -FilePath $obsidianJsonPath -Encoding UTF8 -Force
        Write-DebugLog "Successfully wrote to obsidian.json"
    } catch {
        Write-DebugLog "ERROR writing to obsidian.json: $_"
        throw
    }

    Write-Host "VAULT_ID:$newVaultId"
    Write-DebugLog "Registration complete, vault ID: $newVaultId"
    return $newVaultId
}

# Main execution
Write-DebugLog "====== Script started ======"
Write-DebugLog "Arguments: $VaultPath"
Write-DebugLog "Debug log location: $debugLog"

# Ensure vault path is a directory and exists
if (-not (Test-Path $VaultPath -PathType Container)) {
    Write-DebugLog "ERROR: Vault path is not a valid directory: $VaultPath"
    Write-Host "Error: Vault path '$VaultPath' is not a valid directory."
    exit 1
}

try {
    Register-Vault -VaultPath $VaultPath
    Write-DebugLog "====== Script completed successfully ======"
    exit 0
} catch {
    Write-DebugLog "EXCEPTION: $_"
    Write-DebugLog "Stack trace: $($_.ScriptStackTrace)"
    Write-Host "An error occurred: $_"
    exit 1
}
