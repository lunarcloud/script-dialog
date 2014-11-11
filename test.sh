#!/bin/bash
CURRENT_DIR=$(dirname "$(readlink -f "$0")")/
source "$CURRENT_DIR"/script-ui.sh #multi-ui scripting
relaunchIfNotVisible

APP_NAME="Test Script"
WINDOW_ICON="$CURRENT_DIR/ic_announcement_black_18dp.png"

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
        "NET_OUT" "Allow connections to other hosts" ON \
        "NET_IN" "Allow connections from other hosts" OFF \
        "LOCAL_MOUNT" "Allow mounting of local drives" OFF \
        "REMOTE_MOUNT" "Allow mounting of remote drives" OFF )

messagebox "So you chose to enable: ${ANSWER[@]}"
