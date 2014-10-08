#!/bin/bash
source $(dirname $(readlink -f $0))/script-ui.sh #multi-ui scripting
relaunchIfNotVisible

APP_NAME="Test Script"

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