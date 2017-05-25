script-dialog
=============

Create bash scripts that utilize the best dialog system that is available. Intended for Linux, but has been tested on OSX 10.6 and on Windows via the Cygwin environment and via the git bash terminal, and should work on other unix-like OSs.

* If it's launched from a GUI,
 1. it will prefer kdialog in kde and zenity in anything other environment.
 2. If neither of those are available, then "relaunchIfNotVisible" will relaunch the app in a terminal so that a terminal UI can be used.
* If it's launched in a terminal,
 1. It will use whiptail or dialog.
 2. If neither of those are available, then it will fallback to basic terminal input/output with tools like read and echo.

To Use
-------
Source "script-dialog.sh". The following example assumes it's in the same folder as your script:

    source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/script-dialog.sh
    APP_NAME="Your Title goes here"

Then use the dialog functions, such as:

    ACTIVITY="Test Message"
    messagebox "Hello World!"

Examples of function use
------------------------
"test.sh" will contain uses of every feature.

Licence
--------
The code is under the license described in the "LICENSE" file, which is the LGPL license.