script-dialog
=============

Create bash scripts that utilize the best dialog system that is available. Intended for Linux, but has been tested on OSX 10.6 and on Windows via the Cygwin environment and via the git bash terminal, and should work on other unix-like OSs.

* If it's launched from a GUI,
   1. It will prefer kdialog in Qt-based desktops and zenity in other environments.
   2. If neither of those are available, then "relaunchIfNotVisible" will relaunch the app in a terminal so that a terminal UI can be used.
* If it's launched in a terminal,
   1. It will use whiptail or dialog.
   2. If neither of those are available, then it will fallback to basic terminal input/output with tools like read and echo.

To Use
-------
Source the "script-dialog.sh" script. The following example assumes it's in the same folder as your script:

```bash
    source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/script-dialog.sh
    APP_NAME="Your Title goes here"
```

Then use the dialog functions. The "test.sh" script will contain uses of every feature.

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
|   |   |
| - | - |
| **APP_NAME** | The script's app name, for title bars |
| **ACTIVITY** | The current activity, for title bars |
| **INTERFACE** | Detected if not manually set, the GUI or TUI to use |
| **GUI** | Detected, whether the interface is a GUI not TUI |
| **DETECTED_DESKTOP** | Detected desktop in use |
| **NOCOLORS** | Optional, disables otherwise-detected use of colored/bolded text basic CLI |
| **NOSYMBOLS** | Optional, disables otherwise-detected use of unicode symbols in TUIs |
| **ZENITY_HEIGHT** | Optional, overrides the automatic height of zenity dialogs |
| **ZENITY_WIDTH** | Optional, overrides the automatic width of zenity dialogs |

Functions
----------------
|   |   |
| - | - |
| **superuser** | TODO |
| **_updateGUITitle** | TODO |
| **_updateDialogMaxSize** | TODO |
| **_calculateTextDialogSize** | TODO |
| **relaunchIfNotVisible** | TODO |
| **message-info** | TODO |
| **message-warn** | TODO |
| **message-error** | TODO |
| **messagebox** | TODO |
| **yesno** | TODO |
| **inputbox** | TODO |
| **userandpassword** | TODO |
| **password** | TODO |
| **display-file** | TODO |
| **checklist** | TODO |
| **radiolist** | TODO |
| **progressbar** | TODO |
| **progressbar_update** | TODO |
| **progressbar_finish** | TODO |
| **filepicker** | TODO |
| **folderpicker** | TODO |
| **datepicker** | TODO |