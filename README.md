# Windows Context Menu for Obsidian

A simple utility to add an "Open as Obsidian Vault" option to the Windows Explorer context menu. This allows you to quickly open any folder as a vault in Obsidian without having to launch the app and use the vault switcher manually.

![screenshot of context menu](https://i.imgur.com/your-screenshot.png) 

## Features

- **Quick Access:** Right-click on any folder and open it directly as an Obsidian vault.
- **Works in two ways:**
  1. Right-clicking directly on a folder.
  2. Right-clicking on the background of an open folder in Explorer.
- **Smart Installer:** A simple batch script that automatically finds your `Obsidian.exe` installation. If it can't, it will prompt you for the location.
- **Easy Uninstall:** A separate script is provided to cleanly remove the context menu entries from your registry.

## Getting Started

### Prerequisites

- Windows 10 or Windows 11
- [Obsidian](https://obsidian.md/) must be installed.

### Installation

1.  Go to the [**Releases**](https://github.com/your-username/obsidian-context-menu/releases) page of this repository.
2.  Download the `install_obsidian_context_menu.bat` and `uninstall_obsidian_context_menu.bat` files from the latest release.
3.  Place the scripts anywhere on your computer (e.g., your Desktop).
4.  Right-click on `install_obsidian_context_menu.bat` and select **"Run as administrator"**. This is necessary because modifying the Windows Registry requires elevated permissions.
5.  Follow the on-screen instructions. The script will try to find Obsidian automatically. If it fails, it will ask you to provide the path.

### Uninstallation

1.  Right-click on `uninstall_obsidian_context_menu.bat` and select **"Run as administrator"**.
2.  A command window will appear, confirm the removal, and then close automatically.

## How It Works

This utility works by adding keys to the Windows Registry under `HKEY_CLASSES_ROOT\Directory\shell` and `HKEY_CLASSES_ROOT\Directory\Background\shell`.

The command uses the Obsidian URI scheme (`obsidian://open?vault=VAULT_NAME`) to instruct Obsidian to open a vault. The batch script intelligently extracts the folder name from the path you right-clicked on and passes it to the URI.

**Note:** For the context menu to work, the folder must have been previously opened as a vault in Obsidian, so that Obsidian recognizes its name.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
