#!/usr/bin/env bash
# Multi-UI Scripting - File/Folder Picker Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

#######################################
# Display a file selector dialog
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_SAVE
#   XDG_ICO_FILE_OPEN
#   DOCUMENT_SYMBOL
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   RECMD_SCROLL
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
# ARGUMENTS:
# 	The starting folder
#   "save" or "open" (assume "open" if omitted)
# OUTPUTS:
# 	Path to selected file
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function filepicker() {
  if [ -z ${GUI_ICON+x} ]; then
    if [ "$2" == "save" ]; then
      GUI_ICON=$XDG_ICO_SAVE
    else
      GUI_ICON=$XDG_ICO_FILE_OPEN
    fi
  fi
  _calculate-gui-title
  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2012
    read -r -d '' -a files < <(ls -lBhpa "$1" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_LINES)) $((6+RECMD_COLS)) $RECMD_LINES "${files[@]}" 3>&1 1>&2 2>&3)
    exit_status=$?
    FILE="$1/$SELECTED"

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --fselect "$1"/ 14 48)
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --file-selection --filename "$1"/ )
    exit_status=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    if [ "$2" == "save" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getsavefilename "$1"/ )
    else #elif [ "$2" == "open" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getopenfilename "$1"/ )
    fi
    exit_status=$?
  else
    read -erp "${DOCUMENT_SYMBOL}You need to $2 a file in $1/. Hit enter to browse this folder"

    ls -lBhpa "$1" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED
    exit_status=$?

    # TODO: Add validation - handle empty SELECTED or when SELECTED is a folder

    FILE=$1/$SELECTED
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

    # Ignore choice and relaunch dialog
    if [[ "$SELECTED" == "./" ]]; then
        FILE=$(filepicker "$1" "$2")
    fi

    # Drill into folder
    if [ -d "$FILE" ]; then
        FILE=$(filepicker "$FILE" "$2")
    fi

  echo "$FILE"
}

#######################################
# Display a folder selector dialog
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_FOLDER_OPEN
#   FOLDER_SYMBOL
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   RECMD_SCROLL
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
# ARGUMENTS:
# 	The starting folder
# OUTPUTS:
# 	Path to selected folder
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function folderpicker() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_FOLDER_OPEN
  fi
  _calculate-gui-title
  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2010
    read -r -d '' -a files < <(ls -lBhpa "$1" | grep "^d" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_LINES)) $((6+RECMD_COLS)) $RECMD_LINES "${files[@]}" 3>&1 1>&2 2>&3)
    exit_status=$?
    FILE="$1/$SELECTED"

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --dselect "$1"/ 14 48)
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --file-selection --directory --filename "$1"/ )
    exit_status=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getexistingdirectory "$1"/ )
    exit_status=$?
  else
    read -erp "${FOLDER_SYMBOL}You need to select a folder in $1/. Hit enter to browse this folder"

    # shellcheck disable=SC2010
    ls -lBhpa "$1" | grep "^d" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED
    exit_status=$?

    # TODO: Add validation - handle empty SELECTED or parent directory (..)

    FILE=$1/$SELECTED
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

  echo "$FILE"
}
