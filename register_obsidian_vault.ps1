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
    $existingData = $null
    $existingVaultsCount = 0

    if (Test-Path $obsidianJsonPath) {
        Write-DebugLog "Obsidian JSON exists, reading..."
        try {
            # Create backup before modifying
            $backupPath = "$obsidianJsonPath.backup"
            Copy-Item $obsidianJsonPath $backupPath -Force
            Write-DebugLog "Created backup at: $backupPath"

            $jsonContent = Get-Content -Path $obsidianJsonPath -Raw -Encoding UTF8
            $existingData = $jsonContent | ConvertFrom-Json
            Write-DebugLog "Successfully read obsidian.json"

            # Count existing vaults
            if ($existingData.vaults) {
                $existingVaultsCount = ($existingData.vaults.PSObject.Properties | Measure-Object).Count
            }
            Write-DebugLog "Existing vaults count: $existingVaultsCount"

            # Check if vault already exists
            if ($existingData.vaults) {
                foreach ($prop in $existingData.vaults.PSObject.Properties) {
                    $vaultId = $prop.Name
                    $vaultInfo = $prop.Value
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
            }
        } catch {
            Write-DebugLog "ERROR reading JSON: $_"
            Write-Host "ERROR: Could not read existing obsidian.json"
            throw
        }
    } else {
        Write-DebugLog "Obsidian JSON does not exist, will create new one"
    }

    # Generate new vault ID
    Write-DebugLog "Vault not found, creating new entry"
    $guid = [System.Guid]::NewGuid().ToString("N")
    $newVaultId = $guid.Substring(0, 16)
    Write-DebugLog "Generated vault ID: $newVaultId"

    # Create new vault entry
    $newVault = [PSCustomObject]@{
        path = $vaultPathNormalized
        ts = [int64](([datetime]::UtcNow - [datetime]'1970-01-01').TotalMilliseconds)
    }

    # Build output - preserve existing data
    if ($existingData) {
        # Start with existing data
        $outputData = $existingData

        # Add new vault to existing vaults
        if (-not $outputData.vaults) {
            $outputData | Add-Member -MemberType NoteProperty -Name "vaults" -Value ([PSCustomObject]@{})
        }

        $outputData.vaults | Add-Member -MemberType NoteProperty -Name $newVaultId -Value $newVault -Force

    } else {
        # Create new structure
        $outputData = [PSCustomObject]@{
            vaults = [PSCustomObject]@{}
            openSchemes = [PSCustomObject]@{
                app = $true
            }
        }
        $outputData.vaults | Add-Member -MemberType NoteProperty -Name $newVaultId -Value $newVault
    }

    # Verify vault count before writing
    $newVaultsCount = ($outputData.vaults.PSObject.Properties | Measure-Object).Count
    Write-DebugLog "Vaults after adding new: $newVaultsCount (was: $existingVaultsCount)"

    if ($newVaultsCount -lt $existingVaultsCount) {
        Write-DebugLog "ERROR: Vault count decreased! Aborting write."
        Write-Host "ERROR: Would lose existing vaults. Aborting."
        throw "Vault count check failed"
    }

    # Write to obsidian.json (UTF-8 without BOM)
    try {
        $jsonOutput = $outputData | ConvertTo-Json -Depth 10 -Compress

        # Use .NET to write UTF-8 without BOM (Out-File adds BOM which breaks JSON)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($obsidianJsonPath, $jsonOutput, $utf8NoBom)

        Write-DebugLog "Successfully wrote to obsidian.json (UTF-8 without BOM)"
        Write-DebugLog "Final vault count: $newVaultsCount"
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
