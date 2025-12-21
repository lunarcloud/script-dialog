#!/usr/bin/env bash
# Test script for script-dialog library

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#GUI=false; terminal=false # force relaunching as if launching from GUI without a GUI interface installed, but only do this for testing
#NOSYMBOLS=true
#NOCOLORS=true
# shellcheck source=../script-dialog.sh
# shellcheck disable=SC1091  # Source file path is constructed at runtime
source "${SCRIPT_DIR}"/../script-dialog.sh

relaunch-if-not-visible
# shellcheck disable=SC2034  # APP_NAME is used by script-dialog.sh functions
APP_NAME="Test Script"

ACTIVITY="Salutations"
message-info "Hello $DETECTED_DESKTOP desktop user.\nUsing the ${INTERFACE-basic} interface for dialogs";

ACTIVITY="Inquiry"
yesno "Are you well?";
ANSWER=$?

ACTIVITY="Response"
if [ $ANSWER -eq 0 ]; then
  message-info "Good to hear."
else
  message-warn "Sorry to hear that."
fi

ACTIVITY="Name"
NAME=$(inputbox "What's your name?" "$USER") || exit "$?"

message-info "Nice to meet you, $NAME"

ACTIVITY="Pretending to load..."
{
  for ((i = 0 ; i <= 100 ; i+=5)); do
    # optional text during progress
    if [[ "$((RANDOM % 2))" == "1" ]]; then
      SUB_ACTIVITY="it's thinking"
    else
      SUB_ACTIVITY=""
    fi

    progressbar_update "$i" "$SUB_ACTIVITY"
    sleep 0.2
  done
  progressbar_finish
} | progressbar "$@"

SUGGESTED_USERNAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')  # convert to lower case

ACTIVITY="Pretend Login"
userandpassword S_USER S_PASS "$SUGGESTED_USERNAME"

message-info $"So, that was:\n user: $S_USER\n password: $S_PASS"

ACTIVITY="Enter Birthday"
ANSWER=$(datepicker) || exit "$?"

message-info "Cool, it's on $ANSWER"

ACTIVITY="Pretend Configuration"
CONFIG_OPTS=$( checklist "Select the appropriate network options for this computer" 4  \
        "NET OUT" "Allow connections to other hosts" ON \
        "NET_IN" "Allow connections from other hosts" OFF \
        "LOCAL_MOUNT" "Allow mounting of local drives" OFF \
        "REMOTE_MOUNT" "Allow mounting of remote drives" OFF ) || exit "$?"

message-info "So you chose to enable: ${CONFIG_OPTS[*]}"

ACTIVITY="Pretend Configuration 2"
ANSWER=$(radiolist "Favorite Primary Color? " 4  \
        "blue" "Blue" OFF \
        "yellow" "Yellow" OFF \
        "green" "Green" ON \
        "red" "Red" OFF ) || exit "$?"

message-info "So you like $ANSWER, neat."

ANSWER=$(filepicker "$HOME" "open") || exit "$?"

message-info "File selected was ${ANSWER[*]}"

ACTIVITY="Test Script"
display-file "$0"

ANSWER=$(folderpicker "$HOME") || exit "$?"

message-info "Folder selected was ${ANSWER[*]}"

if [ "$NO_SUDO" == true ]; then
    message-info "No SUDO is available on this system."
else
    # shellcheck disable=SC2034  # ACTIVITY is used by script-dialog.sh functions
    ACTIVITY="SUDO Test"
    sudo -k # clear credentials
    if superuser echo; then
        message-info "Password accepted"
    else
        message-error "Password denied"
    fi
fi

# shellcheck disable=SC2034  # ACTIVITY is used by script-dialog.sh functions
ACTIVITY="Pause Test"
message-info "Next, we'll test the pause feature"
pause "Ready to continue with the script?"

message-info "You chose to continue!"
