script-dialog
=============

Create bash scripts that utilize the best dialog system that is available. Intended for Linux, but has been tested on OSX 10.6 and on Windows via the Cygwin environment and via the git bash terminal, and should work on other unix-like OSs.

* If it's launched from a GUI,
 1. it will prefer kdialog in Qt-based desktops and zenity in anything other environment.
 2. If neither of those are available, then "relaunchIfNotVisible" will relaunch the app in a terminal so that a terminal UI can be used.
* If it's launched in a terminal,
 1. It will use whiptail or dialog.
 2. If neither of those are available, then it will fallback to basic terminal input/output with tools like read and echo.

To Use
-------
Source "script-dialog.sh". The following example assumes it's in the same folder as your script:

    source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/script-dialog.sh
    APP_NAME="Your Title goes here"

Then use the dialog functions. "test.sh" will contain uses of every feature.
