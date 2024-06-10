#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=./script-dialog.sh
source "${SCRIPT_DIR}"/script-dialog.sh

#GUI=false; terminal=false # force relaunching as if launching from GUI without a GUI interface installed, but only do this for testing

relaunchIfNotVisible

APP_NAME="Test Script"
#GUI_ICON="$SCRIPT_DIR/icon.png" # if not set, it'll use standard ones
#INTERFACE="unknown" #force an interface, but only do this for testing

GUI_ICON=$XDG_ICO_INFO
ACTIVITY="Salutations"
messagebox "Hello $desktop desktop user.\nUsing the ${INTERFACE-basic} interface for dialogs";

GUI_ICON=$XDG_ICO_QUESTION
ACTIVITY="Inquiry"
yesno "Are you well?";
ANSWER=$?

GUI_ICON=$XDG_ICO_INFO
ACTIVITY="Response"
if [ $ANSWER -eq 0 ]; then
  messagebox "Good to hear."
else
  messagebox "Sorry to hear that."
fi

GUI_ICON=$XDG_ICO_QUESTION
ACTIVITY="Name"
NAME=$(inputbox "What's your name?" "")

GUI_ICON=$XDG_ICO_QUESTION

GUI_ICON=$XDG_ICO_INFO
messagebox "Nice to meet you, $NAME"

ACTIVITY="Pretending to load..."
{
  for ((i = 0 ; i <= 100 ; i+=5)); do
    progressbar_update "$i"
    sleep 0.2
  done
  progressbar_finish
} | progressbar "$@"

SUGGESTED_USERNAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')  # convert to lower case

GUI_ICON=$XDG_ICO_PASSWORD
ACTIVITY="Pretend Login"
userandpassword USER PASS "$SUGGESTED_USERNAME"

GUI_ICON=$XDG_ICO_INFO
messagebox $"So, that was:\n user: $USER\n password: $PASS"

GUI_ICON=$XDG_ICO_DOCUMENT
ACTIVITY="Test Script"
displayFile "$0"

GUI_ICON=$XDG_ICO_CALENDAR
ACTIVITY="Enter Birthday"
ANSWER=$(datepicker)

GUI_ICON=$XDG_ICO_INFO
messagebox "Cool, it's on $ANSWER"

GUI_ICON=$XDG_ICO_QUESTION
ACTIVITY="Pretend Configuration"
CONFIG_OPTS=$( checklist "Select the appropriate network options for this computer" 4  \
        "NET OUT" "Allow connections to other hosts" ON \
        "NET_IN" "Allow connections from other hosts" OFF \
        "LOCAL_MOUNT" "Allow mounting of local drives" OFF \
        "REMOTE_MOUNT" "Allow mounting of remote drives" OFF )

GUI_ICON=$XDG_ICO_INFO
messagebox "So you chose to enable: ${CONFIG_OPTS[*]}"

GUI_ICON=$XDG_ICO_QUESTION
ACTIVITY="Pretend Configuration 2"
ANSWER=$(radiolist "Favorite Primary Color? " 4  \
        "blue" "Blue" OFF \
        "yellow" "Yellow" OFF \
        "green" "Green" ON \
        "red" "Red" OFF )

GUI_ICON=$XDG_ICO_INFO
messagebox "So you like $ANSWER, neat."

GUI_ICON=$XDG_ICO_FILE_OPEN
ANSWER=$(filepicker "$HOME" "open")

GUI_ICON=$XDG_ICO_INFO
messagebox "File selected was ${ANSWER[*]}"

GUI_ICON=$XDG_ICO_FOLDER_OPEN
ANSWER=$(folderpicker "$HOME")

GUI_ICON=$XDG_ICO_INFO
messagebox "Folder selected was ${ANSWER[*]}"

if [ "$NO_SUDO" == true ]; then
    messagebox "No SUDO is available on this system."
else
    ACTIVITY="SUDO Test"
    sudo -k # clear credentials
    if superuser echo; then
        GUI_ICON=$XDG_ICO_INFO
        messagebox "Password accepted"
    else
        GUI_ICON=$XDG_ICO_ERROR
        messagebox "Password denied"
    fi
fi

exit 0;
