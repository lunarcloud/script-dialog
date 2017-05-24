script-dialog
=============

Create bash scripts that utilize the best dialog system that is available. Intended for Linux, but has been tested on Windows, and should work on other unix-like OSs.

* If it's launched from a GUI,
 1. it will prefer kdialog in kde and zenity in anything other environment.
 2. If neither of those are available, then "relaunchIfNotVisible" will relaunch the app in a terminal so that a terminal UI can be used.
* If it's launched in a terminal,
 1. It will use whiptail or dialog.
 2. If neither of those are available, then it will fallback to basic terminal input/output with tools like read and echo.

To Use
-------
Simply add the following at the top of your script files and have script-dialog.sh in the same directory

    source $(dirname "$(readlink -f "$0")")/script-dialog.sh
    APP_NAME="Your Title goes here"

Or if you've run install.sh

    source /usr/local/bin/script-dialog
    APP_NAME="Your Title goes here"

Then use dialogs

    ACTIVITY="Test Message"
    messagebox "Hello World!"

Examples of function use
------------------------
"test.sh" will contain uses of every feature.

Licence
--------
The code is under the license described in the "LICENSE" file, which is the LGPL license.

The example icon, "ic_announcement_black_18dp.png", is released under an [Attribution-ShareAlike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/) license. as part of Google's Material Design icon set.
