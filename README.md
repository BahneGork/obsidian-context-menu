# Windows Context Menu for Obsidian

A Windows utility that adds "Open as Obsidian Vault" to the context menu. Right-click any folder to instantly open it as an Obsidian vault - even if it's not already configured as one!

## Features

- **Instant Vault Access:** Right-click any folder and open it directly in Obsidian
- **Auto-Initialize:** Automatically creates `.obsidian` configuration if the folder isn't already a vault
- **Smart Registration:** Registers new vaults in Obsidian's vault list automatically
- **Two Context Menus:**
  1. Right-click directly on a folder
  2. Right-click inside an open folder's background
- **Easy Installation:** NSIS installer with automatic Obsidian detection
- **Clean Uninstall:** Removes all registry entries and installed files

## Getting Started

### Prerequisites

- **Windows 10 or Windows 11** (Windows Script Host included by default)
- **[Obsidian](https://obsidian.md/)** - Must be installed

### Installation (Recommended)

1. Go to the [**Releases**](https://github.com/BahneGork/obsidian-context-menu/releases) page
2. Download **`ObsidianContextMenu-Setup.exe`** from the latest release
3. Run the installer
4. The installer will:
   - Automatically detect your Obsidian installation (or prompt you to locate it)
   - Install files to `%LOCALAPPDATA%\ObsidianContextMenu`
   - Add context menu entries to your registry
5. Done! Right-click any folder to try it out

### Alternative Installation (Manual)

If you prefer the batch script method:

1. Download the **Source code (zip)** from the [Releases](https://github.com/BahneGork/obsidian-context-menu/releases) page
2. Extract to a temporary folder
3. Right-click `install_obsidian_context_menu.bat` and select **"Run as administrator"**
4. Follow the on-screen instructions

### Uninstallation

**Using Windows Settings:**
1. Open Windows Settings → Apps → Installed apps
2. Search for "Obsidian Context Menu"
3. Click the three dots → Uninstall

**Using the Uninstaller:**
1. Navigate to `%LOCALAPPDATA%\ObsidianContextMenu`
2. Run `uninstall.exe`

## How It Works

When you right-click a folder and select "Open as Obsidian Vault":

1. **Initialize Vault (if needed)**
   - Checks if the folder contains a `.obsidian` subfolder
   - If not found, creates `.obsidian` and copies default configuration files:
     - `app.json` - Application settings
     - `appearance.json` - Theme and appearance settings
     - `core-plugins.json` - Enabled core plugins
     - `workspace.json` - Workspace layout

2. **Register Vault**
   - JScript (Windows Script Host) reads/updates `%APPDATA%\Roaming\Obsidian\obsidian.json`
   - Adds vault entry with unique ID and path
   - Timestamps the registration
   - Creates automatic backup before modifications

3. **Open in Obsidian**
   - Uses Obsidian URI scheme: `obsidian://open?vault=<vault-id>`
   - Obsidian launches and opens the vault immediately

### Technical Details

- **Registry Keys:** Context menu entries are added to `HKCU\Software\Classes\Directory\shell`
- **Installation Path:** Files are installed to `%LOCALAPPDATA%\ObsidianContextMenu`
- **Vault Registration:** JScript handles JSON manipulation using native JSON.parse() and JSON.stringify()
- **Encoding Safety:** Uses ADODB.Stream to write UTF-8 without BOM (prevents JSON corruption)
- **No Admin Required:** Uses per-user registry (HKCU) instead of system-wide (HKLM)
- **No External Dependencies:** Uses only Windows built-in components (Windows Script Host/cscript.exe)

## Building from Source

To build the installer yourself:

1. **Install NSIS:**
   - Download from [nsis.sourceforge.io](https://nsis.sourceforge.io/)
   - Or install via chocolatey: `choco install nsis`

2. **Clone the repository:**
   ```bash
   git clone https://github.com/BahneGork/obsidian-context-menu.git
   cd obsidian-context-menu
   ```

3. **Build the installer:**
   ```bash
   makensis ObsidianContextMenuInstaller.nsi
   ```

4. **Output:**
   - Creates `ObsidianContextMenu-Setup.exe` in the project directory

## Troubleshooting

### Vault not opening
**Error:** `Vault not found` or Obsidian opens but shows vault picker

**Solution:**
- Check debug log at `%TEMP%\obsidian_vault_register_debug.log`
- Verify `obsidian.json` exists at `%APPDATA%\Roaming\Obsidian\obsidian.json`
- Check that the JScript completed successfully (look for "VAULT_ID:" in output)
- If `obsidian.json` was corrupted, restore from backup: `%APPDATA%\Roaming\Obsidian\obsidian.json.backup`

### Script execution errors
**Error:** Script fails to register vault

**Solution:**
- Windows Script Host (cscript.exe) should be available by default on all Windows 10/11 systems
- Check if Windows Script Host is disabled in your organization's Group Policy
- Review the debug log for specific error messages

### Context menu not appearing
**Solution:**
- Run the uninstaller, then reinstall
- Manually refresh Windows Explorer: `taskkill /f /im explorer.exe && start explorer.exe`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
