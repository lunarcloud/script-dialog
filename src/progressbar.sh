#!/usr/bin/env bash
# Multi-UI Scripting - Progress Bar Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

#######################################
# A pipe that displays a progressbar
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_INFO
#   HOURGLASS_SYMBOL
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
# ARGUMENTS:
# 	the current value of the bar (repeatable, should be piped)
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function progressbar() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_INFO
  fi
  _calculate-gui-title

  export PROGRESS_ACTIVITY=$ACTIVITY

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --backtitle "$APP_NAME" --title "$ACTIVITY" --gauge " " "$RECMD_LINES" "$RECMD_COLS" 0
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --gauge "" "$RECMD_LINES" "$RECMD_COLS" 0
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --progress --text="$ACTIVITY" --auto-close --auto-kill --percentage 0
  elif [ "$INTERFACE" == "kdialog" ]; then
    read -r -d '' -a dbusRef < <( kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --progressbar "$ACTIVITY" 100)
    qdbus "${dbusRef[@]}" Set "" value 0

    mkdir -p /tmp/script-dialog.$$/
    DBUS_BAR_PATH=/tmp/script-dialog.$$/progressbar_dbus
    echo "${dbusRef[@]}" > $DBUS_BAR_PATH

	# wait until finish called to leave function, so internal actions finish
    while [ -e $DBUS_BAR_PATH ]; do
      sleep 1
      read -r "$@" <&0;
    done

    qdbus "${dbusRef[@]}" close
  else
    BAR="[░░░░░░░░░░░░░░░░]"
    echo -ne "\r${HOURGLASS_SYMBOL}$ACTIVITY $BAR 0%"
    cat
  fi
}


#######################################
# Updates the value of the progressbar (call from within the progressbar piped block)
# GLOBALS:
#   HOURGLASS_SYMBOL
#   INTERFACE
#   ACTIVITY
# ARGUMENTS:
# 	the value to set the bar
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function progressbar_update() {
  if [ "$INTERFACE" == "kdialog" ]; then
    DBUS_BAR_PATH=/tmp/script-dialog.$$/progressbar_dbus
    if [ -e $DBUS_BAR_PATH ]; then
      read -r -d '' -a dbusRef < <( cat $DBUS_BAR_PATH )
      if qdbus "${dbusRef[@]}" 2>/dev/null; then
        qdbus "${dbusRef[@]}" Set "" value "$1"
        qdbus "${dbusRef[@]}" setLabelText "$2"
        sleep 0.2 # requires slight sleep
      else
        progressbar_finish
      fi
    else
      echo -e "Could not update progressbar $$"
    fi
  elif [ "$INTERFACE" == "zenity" ]; then
    echo -e "$1"
    echo -e "#$2"
  elif [ "$INTERFACE" == "whiptail" ] || [ "$INTERFACE" == "dialog" ]; then
    echo -e "XXX\n$1\n$2\nXXX"
  else
    case "$1" in
      5)  BAR="[█░░░░░░░░░░░░░░░░░░░]" ;;
      10) BAR="[██░░░░░░░░░░░░░░░░░░]" ;;
      15) BAR="[███░░░░░░░░░░░░░░░░░]" ;;
      20) BAR="[████░░░░░░░░░░░░░░░░]" ;;
      25) BAR="[█████░░░░░░░░░░░░░░░]" ;;
      30) BAR="[██████░░░░░░░░░░░░░░]" ;;
      35) BAR="[███████░░░░░░░░░░░░░]" ;;
      40) BAR="[████████░░░░░░░░░░░░]" ;;
      45) BAR="[█████████░░░░░░░░░░░]" ;;
      50) BAR="[██████████░░░░░░░░░░]" ;;
      55) BAR="[███████████░░░░░░░░░]" ;;
      60) BAR="[████████████░░░░░░░░]" ;;
      65) BAR="[█████████████░░░░░░░]" ;;
      70) BAR="[██████████████░░░░░░]" ;;
      75) BAR="[███████████████░░░░░]" ;;
      80) BAR="[████████████████░░░░]" ;;
      85) BAR="[█████████████████░░░]" ;;
      90) BAR="[██████████████████░░]" ;;
      95) BAR="[███████████████████░]" ;;
      100)BAR="[████████████████████]" ;;
      *)  BAR="[░░░░░░░░░░░░░░░░░░░░]";;
    esac

    TEXT=""
    if [[ "$2" != "" ]]; then
      TEXT=": $2"
    fi

    printf '\r\e[2K'
    echo -e "\r${HOURGLASS_SYMBOL}$ACTIVITY $BAR ${1}% $TEXT\c"
  fi
}

#######################################
# Completes the the progressbar (call from within the progressbar piped block)
# GLOBALS:
#   INTERFACE
# ARGUMENTS:
# 	n/a
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function progressbar_finish() {
  if [ "$INTERFACE" == "kdialog" ]; then
	DBUS_BAR_FOLDER=/tmp/script-dialog.$$
    DBUS_BAR_PATH=$DBUS_BAR_FOLDER/progressbar_dbus
    if [ -e $DBUS_BAR_PATH ]; then
		rm $DBUS_BAR_PATH
		rmdir $DBUS_BAR_FOLDER --ignore-fail-on-non-empty
	else
		echo "Could not close progressbar $$"
    fi
  elif [ "$INTERFACE" != "whiptail" ] && [ "$INTERFACE" != "dialog" ] && [ "$INTERFACE" != "zenity" ]; then
    echo ""
  fi
  unset PROGRESS_ACTIVITY
}
