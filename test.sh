#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
source "$CURRENT_DIR"/script-ui.sh #folder local version
#source /usr/local/bin/script-ui #installed version

#GUI=false; terminal=false # force relaunching as if launching from GUI without a GUI interface installed, but only do this for testing

relaunchIfNotVisible

APP_NAME="Test Script"
WINDOW_ICON="$CURRENT_DIR/ic_announcement_black_18dp.png"

#INTERFACE="text" #force an interface, but only do this for testing

ACTIVITY="Pretending to load..."
{
    for ((i = 0 ; i <= 100 ; i+=5)); do
        progressbar_update $i
        sleep 0.2
    done
} | progressbar
progressbar_finish

ACTIVITY="Salutations"
messagebox "Hello World";

ACTIVITY="Inquiry"
yesno "Are you well?";
ANSWER=$?

ACTIVITY="Response"
if [ $ANSWER -eq 0 ]; then
    messagebox "Good to hear."
else
    messagebox "Sorry to hear that."
fi

ACTIVITY="Name"
ANSWER=$(inputbox "What's your name?" " ")

messagebox "Nice to meet you, $ANSWER"

ACTIVITY="APT Repositories"
displayFile /etc/apt/sources.list

ACTIVITY="Pretend Login"
ANSWER=$(userandpassword Username Password)
USERNAME=`echo $ANSWER | cut -d'|' -f1`
PASSWORD=`echo $ANSWER | cut -d'|' -f2`

messagebox "So, that was: $USERNAME - $PASSWORD"

ACTIVITY="Enter Birthday"
ANSWER=$(datepicker)
messagebox "Cool, it's on $ANSWER"

ACTIVITY="Pretend Configuration"
ANSWER=$( checklist "Select the appropriate network options for this computer" 4  \
        "NET OUT" "Allow connections to other hosts" ON \
        "NET_IN" "Allow connections from other hosts" OFF \
        "LOCAL_MOUNT" "Allow mounting of local drives" OFF \
        "REMOTE_MOUNT" "Allow mounting of remote drives" OFF )
messagebox "So you chose to enable: $ANSWER"

ACTIVITY="Pretend Configuration 2"
ANSWER=$(radiolist "Favorite Primary Color? " 4  \
        "blue" "Blue" OFF \
        "yellow" "Yellow" OFF \
        "green" "Green" ON \
        "red" "Red" OFF )
messagebox "So you like $ANSWER, neat."

ANSWER=$(filepicker $HOME "open")
messagebox "File selected was $ANSWER"

clear
