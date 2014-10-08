#!/bin/bash
source $(dirname $(readlink -f $0))/script-ui.sh #multi-ui scripting

messagebox "Hello World";

yesno "Hello World?";
ANSWER=$?

messagebox "$ANSWER"
