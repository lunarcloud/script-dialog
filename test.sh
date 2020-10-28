#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=./script-dialog.sh
source "${SCRIPT_DIR}"/script-dialog.sh

#GUI=false; terminal=false # force relaunching as if launching from GUI without a GUI interface installed, but only do this for testing

relaunchIfNotVisible

APP_NAME="Test Script"
#WINDOW_ICON="$SCRIPT_DIR/icon.png" # if not set, it'll use standard ones
#INTERFACE="kdialog" #force an interface, but only do this for testing

if [ "$NO_SUDO" == true ]; then
    messagebox "No SUDO is available on this system."
else
    ACTIVITY="SUDO Test"
    sudo -k # clear credentials
    if superuser echo; then
        WINDOW_ICON=$(standardIconInfo)
        messagebox "Password accepted"
    else
        WINDOW_ICON=$(standardIconError)
        messagebox "Password denied"
    fi
fi

ACTIVITY="Salutations"
messagebox "Hello World";

WINDOW_ICON=$(standardIconQuestion)
ACTIVITY="Inquiry"
yesno "Are you well?";
ANSWER=$?

WINDOW_ICON=$(standardIconInfo)
ACTIVITY="Response"
if [ $ANSWER -eq 0 ]; then
  messagebox "Good to hear."
else
  messagebox "Sorry to hear that."
fi

WINDOW_ICON=$(standardIconQuestion)
ACTIVITY="Name"
NAME=$(inputbox "What's your name?" " ")

WINDOW_ICON=$(standardIconQuestion)

WINDOW_ICON=$(standardIconInfo)
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

WINDOW_ICON=$(standardIconPassword)
ACTIVITY="Pretend Login"
userandpassword USER PASS "$SUGGESTED_USERNAME"

WINDOW_ICON=$(standardIconInfo)
messagebox "So, that was: user: $USER - password: $PASS"

WINDOW_ICON=$(standardIconDocument)
ACTIVITY="Test Script"
displayFile "$0"

WINDOW_ICON=$(standardIconCalendar)
ACTIVITY="Enter Birthday"
ANSWER=$(datepicker)

WINDOW_ICON=$(standardIconInfo)
messagebox "Cool, it's on $ANSWER"

WINDOW_ICON=$(standardIconQuestion)
ACTIVITY="Pretend Configuration"
CONFIG_OPTS=$( checklist "Select the appropriate network options for this computer" 4  \
        "NET OUT" "Allow connections to other hosts" ON \
        "NET_IN" "Allow connections from other hosts" OFF \
        "LOCAL_MOUNT" "Allow mounting of local drives" OFF \
        "REMOTE_MOUNT" "Allow mounting of remote drives" OFF )

WINDOW_ICON=$(standardIconInfo)
messagebox "So you chose to enable: ${CONFIG_OPTS[*]}"

WINDOW_ICON=$(standardIconQuestion)
ACTIVITY="Pretend Configuration 2"
ANSWER=$(radiolist "Favorite Primary Color? " 4  \
        "blue" "Blue" OFF \
        "yellow" "Yellow" OFF \
        "green" "Green" ON \
        "red" "Red" OFF )

WINDOW_ICON=$(standardIconInfo)
messagebox "So you like $ANSWER, neat."

WINDOW_ICON=$(standardIconFileOpen)
ANSWER=$(filepicker "$HOME" "open")

WINDOW_ICON=$(standardIconInfo)
messagebox "File selected was ${ANSWER[*]}"

WINDOW_ICON=$(standardIconFolderOpen)
ANSWER=$(folderpicker "$HOME")

WINDOW_ICON=$(standardIconInfo)
messagebox "Folder selected was ${ANSWER[*]}"

exit 0;
