script-dialog
=============

Allows you to use the best scripting UIs available in a common way

If it's launched in a terminal it will use terminal UI, whiptail or dialog
If launched without a terminal it will prefer kdialog in kde and zenity in anything other environment

To Use
-------
Simply add the following at the top of your script files and have script-ui.sh in the same directory

    source $(dirname $(readlink -f $0))/script-ui.sh #multi-ui scripting
    APP_NAME="Your Title goes here"

Then use dialogs

    ACTIVITY="Test Message"
    messagebox "Hello World!"

TODO
------

  * File Display
  * Password Box
  * Checklist
  * Radio List
  * Progress Bar
  * Calendar
