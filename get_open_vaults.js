// JScript to get currently open vault IDs from obsidian.json
var fso = new ActiveXObject("Scripting.FileSystemObject");
var shell = new ActiveXObject("WScript.Shell");

// JSON parser for JScript
function parseJSON(jsonString) {
    return eval('(' + jsonString + ')');
}

function getObsidianJsonPath() {
    var appData = shell.ExpandEnvironmentStrings("%APPDATA%");
    return appData + "\\Obsidian\\obsidian.json";
}

function getOpenVaults() {
    var obsidianJsonPath = getObsidianJsonPath();

    if (!fso.FileExists(obsidianJsonPath)) {
        WScript.Quit(0);
    }

    try {
        var file = fso.OpenTextFile(obsidianJsonPath, 1, false, 0);
        var jsonText = file.ReadAll();
        file.Close();

        var data = parseJSON(jsonText);

        if (!data.vaults) {
            WScript.Quit(0);
        }

        var openVaults = [];
        for (var vaultId in data.vaults) {
            if (data.vaults.hasOwnProperty(vaultId)) {
                var vaultInfo = data.vaults[vaultId];
                if (vaultInfo.open === true) {
                    openVaults.push(vaultId);
                }
            }
        }

        // Output comma-separated list of open vault IDs
        if (openVaults.length > 0) {
            WScript.Echo(openVaults.join(","));
        }

    } catch (e) {
        // Fail silently
    }
}

getOpenVaults();
