#!/usr/bin/env bash
# Multi-UI Scripting - Input Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

#######################################
# Display a text input box
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   SYMBOL
#   QUESTION_SYMBOL
#   TEST_STRING
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
# ARGUMENTS:
# 	The text to display
#   The initial input value
# OUTPUTS:
# 	the entered text
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function inputbox() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi

  if [ -z ${SYMBOL+x} ]; then
    local SYMBOL=$QUESTION_SYMBOL
  fi

  _calculate-gui-title
  TEST_STRING="${QUESTION_SYMBOL} $1"
  _calculate-tui-size

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_LINES" "$RECMD_COLS" "$2" 3>&1 1>&2 2>&3)
    exit_status=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_LINES" "$RECMD_COLS" "$2" 3>&1 1>&2 2>&3)
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT="$(zenity --entry --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --text="$1" --entry-text "$2")"
    exit_status=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT="$(kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --inputbox "$1" "$2")"
    exit_status=$?
  else
    read ${NO_READ_DEFAULT+-i "$2"} -rep "${SYMBOL}${bold}$1: ${normal}" INPUT
    exit_status=$?
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

  echo "$INPUT"
}


#######################################
# Display a (single or series of) input box(es) for entering a username and a password
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_PASSWORD
#   PASSWORD_SYMBOL
#   TEST_STRING
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
#   $1
#   $2
# ARGUMENTS:
#   The name of the username variable
#   The name of the password variable
#   The initial username input value
# 	The text to display for username entry
# 	The text to display for password entry
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function userandpassword() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_PASSWORD
  fi
  _calculate-gui-title
  TEST_STRING="$4"
  _calculate-tui-size

  local __uservar="$1"
  local __passvar="$2"
  local SUGGESTED_USERNAME="$3"
  local USER_TEXT="$4"
  if [ "$USER_TEXT" == "" ]; then USER_TEXT="Username"; fi
  local PASS_TEXT="$5"
  if [ "$PASS_TEXT" == "" ]; then PASS_TEXT="Password"; fi
  local CREDS=()

  if [ "$INTERFACE" == "whiptail" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$PASS_TEXT" "$RECMD_LINES" "$RECMD_COLS" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    mapfile -t CREDS < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --insecure --mixedform "Login:" "$RECMD_LINES" "$RECMD_COLS" 0 "Username: " 1 1 "$SUGGESTED_USERNAME" 1 11 22 0 0 "Password :" 2 1 "" 2 11 22 0 1 3>&1 1>&2 2>&3 )
  elif [ "$INTERFACE" == "zenity" ]; then
    ENTRY=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --password --username "$SUGGESTED_USERNAME")
    local exit_status=$?
    CREDS[0]=$(echo "$ENTRY" | cut -d'|' -f1)
    CREDS[1]=$(echo "$ENTRY" | cut -d'|' -f2)
    # Exit script if dialog was cancelled
    if [ $exit_status -ne 0 ]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  elif [ "$INTERFACE" == "kdialog" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$PASS_TEXT")
  else
    read ${NO_READ_DEFAULT+-i "$SUGGESTED_USERNAME"} -rep "${QUESTION_SYMBOL}${bold}$USER_TEXT: ${normal}" "CREDS[0]"
    local exit_status=$?
    if [ $exit_status -eq 0 ]; then
      read -srp "${bold}${PASSWORD_SYMBOL}$PASS_TEXT: ${normal}" "CREDS[1]"
      exit_status=$?
    fi
    echo
    # Exit script if dialog was cancelled
    if [ $exit_status -ne 0 ]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  fi
  local exit_status=$?

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi
  
  eval "$__uservar"="'${CREDS[0]}'"
  eval "$__passvar"="'${CREDS[1]}'"
}

#######################################
# Display an input box for entering a password
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_PASSWORD
#   PASSWORD_SYMBOL
#   TEST_STRING
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
# ARGUMENTS:
# 	The text to display for password entry
# OUTPUTS:
# 	the entered text
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function password() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_PASSWORD
  fi
  _calculate-gui-title
  TEST_STRING="${PASSWORD_SYMBOL}$1"
  _calculate-tui-size

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    PASSWORD=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_LINES" "$RECMD_COLS" 3>&1 1>&2 2>&3)
    exit_status=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    PASSWORD=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_LINES" "$RECMD_COLS" 3>&1 1>&2 2>&3)
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    PASSWORD=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --password)
    exit_status=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    PASSWORD=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$1")
    exit_status=$?
  else
    read -srp "${PASSWORD_SYMBOL}${bold}$ACTIVITY: ${normal}" PASSWORD
    exit_status=$?
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

  echo "$PASSWORD"
}
