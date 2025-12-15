script-dialog
=============

[![GitHub License](https://img.shields.io/github/license/lunarcloud/script-dialog)](https://github.com/lunarcloud/script-dialog/blob/main/LICENSE)
[![GitHub top language](https://img.shields.io/github/languages/top/lunarcloud/script-dialog)](https://github.com/lunarcloud/script-dialog/pulse)

![Code Quality](https://github.com/lunarcloud/script-dialog/actions/workflows/analyze.yml/badge.svg)

Create bash scripts that utilize the best dialog system that is available. Intended for Linux, but has been tested on macOS and Windows, and should work on other unix-like OSs.

* If it's launched from a _GUI_ (like a `.desktop` shortcut or the `dolphin` file manager),
   1. It will prefer **kdialog** in Qt-based desktops and **zenity** in other environments.
   2. If neither of those are available, then `relaunch-if-not-visible` will relaunch the app in a terminal so that a terminal UI can be used.
* If it's launched in a _terminal_,
   1. It will use **whiptail** or **dialog**.
   2. If neither of those are available, then it will fallback to basic terminal input/output with tools like `read` and `echo`.

To Use
-------
Source `script-dialog.sh`. Then use the library's [variables](#global-variables) and [functions](#Functions). The `test.sh` script will contain examples of each feature.

The following example assumes it's in the same folder as your script:

```bash
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    source "${SCRIPT_DIR}"/script-dialog.sh

    APP_NAME="My Utility Script"

    ACTIVITY="Intro"
    message-info "Hello!"
```


FAQ
----
Scripts open in a text editor instead of running, what gives?
One of 2 things has happened:

  * The script has not been marked as "executable" in it's permission properties.

    That's the execute bit, `chmod +x test.sh`, for you terminal folks.

  * Some desktop environments do this as default script behavior, assuming scripts are only run from terminal and edited from GUIs.

    You may have to change your file manager preferences on scripts or "Executable Text Files", or right click and choose to "Run As Program".

    The latter option may run the script in a terminal instead of GUI. Not much can be done about "GNOME choses to force scripts to open via terminal" type issues. If this is for a permanent script, create an application shortcut (by creating a `.desktop` file in `$HOME/.local/share/applications/`).

Global Variables
----------------
| Name | Use | Description |
| ---- | --- | ----------- |
| **APP_NAME** | User-defined | The script's app name, for title bars |
| **ACTIVITY** | User-defined | The current activity, for title bars |
| **INTERFACE** | Override or Detected | the GUI or TUI to use |
| **GUI** | Detected | Whether the interface is a GUI not TUI |
| **DETECTED_DESKTOP** | Detected | Desktop in use |
| **NOCOLORS** | Optional override | disables otherwise-detected use of colored/bolded text basic CLI |
| **NOSYMBOLS** | Optional override |disables otherwise-detected use of unicode symbols in TUIs |
| **ZENITY_HEIGHT** | Optional override | height of zenity dialogs |
| **ZENITY_WIDTH** | Optional override | width of zenity dialogs |

Functions
----------------
| Name | Description | Arguments | Output or Return |
| ---- | ----------- | --------- | ---------------- |
| **superuser** | Attempts to run a privileged command (sudo or equivalent) | Command to run with elevated privilege | return code 0 if success, non-zero otherwise |
| **relaunch-if-not-visible** | if neither GUI nor terminal interfaces can be used, relaunch the script in a terminal emulator | |  |
| **message-info** | Display an 'info' message box | The text to display | |
| **message-warn** | Display a 'warning' message box | The text to display | |
| **message-error** | Display an 'error' message box | The text to display | |
| **messagebox** | Display a message box | The text to display | |
| **pause** | Display a "Continue or Quit" dialog with optional message | Optional message (defaults to "Continue?") | Exits script if user chooses Quit, returns 0 if Continue |
| **yesno** | Display a yes-no decision message box | The text to display | return code 0 if yes, 1 if no |
| **inputbox** | Display a text input box | <ol><li>The text to display</li><li>The initial input value</li></ol> | the entered text |
| **userandpassword** | Display a (single or series of) input box(es) for entering a username and a password |  <ol><li>The name of the username variable</li><li>The name of the password variable</li><li>The initial username input value</li><li>The text to display for username entry</li><li>The text to display for password entry</li></ol> | |
| **password** | Display an input box for entering a password | The text to display for password entry | the entered text |
| **display-file** | Display the contents of a file | <ol><li>The file whose text to display</li><li>width of GUI display (512 if omitted)</li><li>height of GUI display (640 if omitted)</li></ol> | |
| **checklist** | Display a list of multiply-selectable items | <ol><li>The file whose text to display</li><li>Number of options</li><li>First item's value</li><li>First item's description</li><li>First item's default checked status (ON or OFF)</li><li>(repeat for all items)</li></ol> | Value text of the selected item (or the default item) |
| **radiolist** | Display a list of singularly-selectable items | <ol><li>The file whose text to display</li><li>Number of options</li><li>First item's value</li><li>First item's description</li><li>First item's default selected status (ON or OFF)</li><li>(repeat for all items)</li></ol> | Value text of the selected item (or the default item) |
| **progressbar** | A pipe that displays a progressbar | the current value of the bar (repeatable, should be piped) | |
| **progressbar_update** | Updates the value of the progressbar (call from within the progressbar piped block) | <ol><li>the new percentage value</li><li>the new status text</li></ol> | |
| **progressbar_finish** | Completes the progressbar (call from within the progressbar piped block) | | |
| **filepicker** | Display a file selector dialog | <ol><li>The starting folder</li><li>"save" or "open" (assume "open" if omitted)</li></ol> | Path to selected file | |
| **folderpicker** | Display a folder selector dialog | The starting folder | Path to selected folder |
| **datepicker** | Display a calendar date selector dialog | The starting folder | Selected date text (DD/MM/YYYY) |

Screenshot Utility
------------------
The `screenshot-dialogs.sh` script helps create screenshots of dialog features using different interfaces. This is useful for:
- Documenting features in pull requests
- Creating visual demonstrations of dialog variations
- Testing dialog appearance across different interfaces

**Note**: This utility requires a graphical environment (X11 or Wayland) to capture screenshots. It will not work in headless environments.

### Usage
```bash
# Screenshot all available interfaces with common dialogs
./screenshot-dialogs.sh

# Screenshot a specific interface with all common dialogs
./screenshot-dialogs.sh --interface zenity

# Screenshot a specific dialog type with all available interfaces
./screenshot-dialogs.sh --dialog info

# Screenshot a specific interface and dialog type
./screenshot-dialogs.sh --interface whiptail --dialog yesno

# Specify custom output directory
./screenshot-dialogs.sh --output ./my-screenshots

# Show all options
./screenshot-dialogs.sh --help
```

### Requirements
The script requires one of the following screenshot tools to be installed:
- `import` (from ImageMagick) - recommended
- `scrot`
- `gnome-screenshot`
- `spectacle`
- `maim`

On Ubuntu/Debian: `sudo apt install imagemagick`
On macOS: `brew install imagemagick`
