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

    # Read existing obsidian.json if it exists
    $vaults = @{}
    $dataObj = $null

    if (Test-Path $obsidianJsonPath) {
        Write-DebugLog "Obsidian JSON exists, reading..."
        try {
            $jsonContent = Get-Content -Path $obsidianJsonPath -Raw -Encoding UTF8
            $dataObj = $jsonContent | ConvertFrom-Json
            Write-DebugLog "Successfully read obsidian.json"

            # Convert vaults PSCustomObject to hashtable
            if ($dataObj.vaults) {
                $dataObj.vaults.PSObject.Properties | ForEach-Object {
                    $vaults[$_.Name] = @{
                        path = $_.Value.path
                        ts = $_.Value.ts
                    }
                }
            }
        } catch {
            Write-DebugLog "JSON decode error: $_"
            Write-Host "Warning: Could not decode existing obsidian.json. Creating new one."
        }
    } else {
        Write-DebugLog "Obsidian JSON does not exist, will create new one"
    }

    Write-DebugLog "Existing vaults count: $($vaults.Count)"

    # Check if vault already exists by path
    foreach ($vaultId in $vaults.Keys) {
        $vaultInfo = $vaults[$vaultId]
        $existingPath = ""

        if ($vaultInfo.path) {
            try {
                $existingPath = (Resolve-Path $vaultInfo.path -ErrorAction SilentlyContinue).Path
            } catch {
                $existingPath = $vaultInfo.path
            }
        }

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
    $vaults[$newVaultId] = @{
        path = $vaultPathNormalized
        ts = [int64](([datetime]::UtcNow - [datetime]'1970-01-01').TotalMilliseconds)
    }
    Write-DebugLog "Added vault to vaults dictionary"

    # Create output object for JSON
    $outputData = [PSCustomObject]@{
        vaults = [PSCustomObject]@{}
        openSchemes = [PSCustomObject]@{
            app = $true
        }
    }

    # Add all vaults to output
    foreach ($vaultId in $vaults.Keys) {
        $outputData.vaults | Add-Member -MemberType NoteProperty -Name $vaultId -Value ([PSCustomObject]@{
            path = $vaults[$vaultId].path
            ts = $vaults[$vaultId].ts
        })
    }

    # Write to obsidian.json
    try {
        $jsonOutput = $outputData | ConvertTo-Json -Depth 10
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
