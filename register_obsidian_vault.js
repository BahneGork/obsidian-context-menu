// JScript for registering Obsidian vaults
// Uses built-in Windows Script Host (cscript.exe)

var fso = new ActiveXObject("Scripting.FileSystemObject");
var shell = new ActiveXObject("WScript.Shell");

// Get command line arguments
var args = WScript.Arguments;
if (args.Length < 1) {
    WScript.Echo("Usage: cscript register_obsidian_vault.js <vault_path>");
    WScript.Quit(1);
}

var vaultPath = args(0);

// Debug log file
var tempFolder = shell.ExpandEnvironmentStrings("%TEMP%");
var debugLog = tempFolder + "\\obsidian_vault_register_debug.log";

function writeDebugLog(message) {
    try {
        var logFile = fso.OpenTextFile(debugLog, 8, true); // 8 = ForAppending
        var timestamp = new Date().toISOString().replace('T', ' ').substr(0, 19);
        logFile.WriteLine("[" + timestamp + "] " + message);
        logFile.Close();
    } catch (e) {
        // Fail silently
    }
}

function getObsidianJsonPath() {
    var appData = shell.ExpandEnvironmentStrings("%APPDATA%");
    return appData + "\\Obsidian\\obsidian.json";
}

function generateVaultId() {
    // Generate 16 hex characters
    var chars = "0123456789abcdef";
    var id = "";
    for (var i = 0; i < 16; i++) {
        id += chars.charAt(Math.floor(Math.random() * 16));
    }
    return id;
}

function registerVault(vaultPath) {
    writeDebugLog("=== Starting registration for: " + vaultPath);

    var obsidianJsonPath = getObsidianJsonPath();
    writeDebugLog("Obsidian JSON path: " + obsidianJsonPath);

    // Ensure directory exists
    var obsidianDir = fso.GetParentFolderName(obsidianJsonPath);
    if (!fso.FolderExists(obsidianDir)) {
        fso.CreateFolder(obsidianDir);
        writeDebugLog("Created directory: " + obsidianDir);
    }

    // Normalize path
    var vaultPathNormalized = fso.GetAbsolutePathName(vaultPath);
    writeDebugLog("Normalized vault path: " + vaultPathNormalized);

    // Read existing JSON
    var data;
    var existingVaultsCount = 0;

    if (fso.FileExists(obsidianJsonPath)) {
        writeDebugLog("Obsidian JSON exists, reading...");

        // Create backup
        var backupPath = obsidianJsonPath + ".backup";
        fso.CopyFile(obsidianJsonPath, backupPath, true);
        writeDebugLog("Created backup at: " + backupPath);

        try {
            // Use ADODB.Stream to read UTF-8 without BOM
            WScript.Echo("DEBUG: Attempting to read with ADODB.Stream");
            writeDebugLog("Attempting to read with ADODB.Stream");
            var stream = new ActiveXObject("ADODB.Stream");
            WScript.Echo("DEBUG: Stream object created");
            stream.Type = 2; // adTypeText
            stream.Charset = "UTF-8";
            WScript.Echo("DEBUG: Charset set to UTF-8");
            stream.Open();
            WScript.Echo("DEBUG: Stream opened");
            writeDebugLog("Stream opened, loading file...");
            stream.LoadFromFile(obsidianJsonPath);
            WScript.Echo("DEBUG: File loaded");
            writeDebugLog("File loaded, reading text...");
            var jsonText = stream.ReadText();
            WScript.Echo("DEBUG: Text read, length: " + jsonText.length);
            stream.Close();
            writeDebugLog("Stream closed, parsing JSON...");

            data = JSON.parse(jsonText);
            WScript.Echo("DEBUG: JSON parsed successfully");
            writeDebugLog("Successfully parsed obsidian.json");

            // Count existing vaults
            if (data.vaults) {
                for (var key in data.vaults) {
                    if (data.vaults.hasOwnProperty(key)) {
                        existingVaultsCount++;
                    }
                }
            }
            writeDebugLog("Existing vaults count: " + existingVaultsCount);

        } catch (e) {
            writeDebugLog("ERROR reading JSON: " + e.message);
            writeDebugLog("ERROR number: " + e.number);
            writeDebugLog("ERROR description: " + e.description);
            WScript.Echo("ERROR: Could not read existing obsidian.json");
            WScript.Quit(1);
        }
    } else {
        writeDebugLog("Obsidian JSON does not exist, will create new one");
        data = {
            vaults: {},
            openSchemes: { app: true }
        };
    }

    // Ensure vaults object exists
    if (!data.vaults) {
        data.vaults = {};
    }

    // Check if vault already exists
    for (var vaultId in data.vaults) {
        if (data.vaults.hasOwnProperty(vaultId)) {
            var vaultInfo = data.vaults[vaultId];
            var existingPath = vaultInfo.path;

            writeDebugLog("Checking vault " + vaultId + ": " + existingPath);

            // Normalize for comparison
            try {
                existingPath = fso.GetAbsolutePathName(existingPath);
            } catch (e) {
                // Path might not exist anymore
            }

            if (existingPath.toLowerCase() === vaultPathNormalized.toLowerCase()) {
                writeDebugLog("Found existing vault with ID: " + vaultId);
                WScript.Echo("VAULT_ID:" + vaultId);
                WScript.Quit(0);
            }
        }
    }

    // Generate new vault ID
    writeDebugLog("Vault not found, creating new entry");
    var newVaultId = generateVaultId();
    writeDebugLog("Generated vault ID: " + newVaultId);

    // Add new vault
    data.vaults[newVaultId] = {
        path: vaultPathNormalized,
        ts: new Date().getTime()
    };

    // Count vaults after adding
    var newVaultsCount = 0;
    for (var key in data.vaults) {
        if (data.vaults.hasOwnProperty(key)) {
            newVaultsCount++;
        }
    }

    writeDebugLog("Vaults after adding new: " + newVaultsCount + " (was: " + existingVaultsCount + ")");

    // Safety check
    if (newVaultsCount < existingVaultsCount) {
        writeDebugLog("ERROR: Vault count decreased! Aborting write.");
        WScript.Echo("ERROR: Would lose existing vaults. Aborting.");
        WScript.Quit(1);
    }

    // Write JSON (compact format, UTF-8 without BOM)
    try {
        var jsonOutput = JSON.stringify(data);

        // Use ADODB.Stream to write UTF-8 without BOM
        var stream = new ActiveXObject("ADODB.Stream");
        stream.Type = 2; // adTypeText
        stream.Charset = "UTF-8";
        stream.Open();
        stream.WriteText(jsonOutput);
        stream.SaveToFile(obsidianJsonPath, 2); // 2 = adSaveCreateOverWrite
        stream.Close();

        writeDebugLog("Successfully wrote to obsidian.json (UTF-8 without BOM)");
        writeDebugLog("Final vault count: " + newVaultsCount);

    } catch (e) {
        writeDebugLog("ERROR writing to obsidian.json: " + e.message);
        WScript.Echo("ERROR: Failed to write obsidian.json");
        WScript.Quit(1);
    }

    WScript.Echo("VAULT_ID:" + newVaultId);
    writeDebugLog("Registration complete, vault ID: " + newVaultId);
}

// Main execution
writeDebugLog("====== Script started ======");
writeDebugLog("Arguments: " + vaultPath);
writeDebugLog("Debug log location: " + debugLog);

// Check if path exists and is a directory
if (!fso.FolderExists(vaultPath)) {
    writeDebugLog("ERROR: Vault path is not a valid directory: " + vaultPath);
    WScript.Echo("Error: Vault path '" + vaultPath + "' is not a valid directory.");
    WScript.Quit(1);
}

try {
    registerVault(vaultPath);
    writeDebugLog("====== Script completed successfully ======");
    WScript.Quit(0);
} catch (e) {
    writeDebugLog("EXCEPTION: " + e.message);
    WScript.Echo("An error occurred: " + e.message);
    WScript.Quit(1);
}
