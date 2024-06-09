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

    On GNOME, right click the script and choose "Run as a Program".
