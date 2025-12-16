#!/usr/bin/env bash
# Multi-UI Scripting - Message Box Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

#######################################
# Display an 'info' message box
# GLOBALS:
#   INFO_SYMBOL
# ARGUMENTS:
# 	The text to display
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function message-info() {
  local SYMBOL=$INFO_SYMBOL
  messagebox "$@"
}

#######################################
# Display a 'warning' message box
# GLOBALS:
# 	GUI_ICON
#   XDG_ICO_WARN
#   WARN_SYMBOL
# ARGUMENTS:
# 	The text to display
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function message-warn() {
  GUI_ICON=$XDG_ICO_WARN
  local KDIALOG_ARG=--sorry
  local SYMBOL=$WARN_SYMBOL
  echo -n "${yellow}"
  messagebox "$@"
  echo -n "${normal}"
}

#######################################
# Display an 'error' message box
# GLOBALS:
# 	GUI_ICON
# ARGUMENTS:
# 	The text to display
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function message-error() {
  GUI_ICON=$XDG_ICO_ERROR
  local KDIALOG_ARG=--error
  local SYMBOL=$ERR_SYMBOL
  echo -n "${red}"
  messagebox "$@"
  echo -n "${normal}"
}

#######################################
# Display a message box
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   SYMBOL
#   TEST_STRING
#   INTERFACE
#   RECMD_SCROLL
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
#   KDIALOG_ARG
# ARGUMENTS:
# 	The text to display
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function messagebox() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_INFO
  fi
  if [ -z ${KDIALOG_ARG+x} ]; then
    KDIALOG_ARG=--msgbox
  fi
  _calculate-gui-title
  TEST_STRING="${SYMBOL}$1"
  _calculate-tui-size

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "${SYMBOL}$1" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "${SYMBOL}$1" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --info --text "$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" "$KDIALOG_ARG" "$1"
  else
    echo -e "${SYMBOL}$1"
  fi
}


#######################################
# Display a "Continue or Quit" dialog
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   TEST_STRING
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
#   QUESTION_SYMBOL
# ARGUMENTS:
# 	Optional message to display (defaults to "Continue?")
# OUTPUTS:
# 	n/a
# RETURN:
# 	Exits script if user chooses to quit, otherwise returns 0
#######################################
function pause() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  _calculate-gui-title

  local MESSAGE="${1:-Continue?}"
  TEST_STRING="${QUESTION_SYMBOL}$MESSAGE"
  _calculate-tui-size

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yes-button "Continue" --no-button "Quit" --yesno "${QUESTION_SYMBOL}$MESSAGE" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yes-label "Continue" --no-label "Quit" --yesno "${QUESTION_SYMBOL}$MESSAGE" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --question --text "$MESSAGE" --ok-label="Continue" --cancel-label="Quit"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --yes-label "Continue" --no-label "Quit" --yesno "$MESSAGE"
  else
    echo -ne "${QUESTION_SYMBOL}${bold}$MESSAGE (press Enter to continue, q to quit): ${normal}" 3>&1 1>&2 2>&3
    read -r answer
    [[ "${answer,,}" != "q" ]]
  fi
  local exit_status=$?

  # Exit script if user chose to quit
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi
}


#######################################
# Display a yes-no decision message box
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   TEST_STRING
#   INTERFACE
#   RECMD_LINES
#   RECMD_COLS
#   APP_NAME
#   ACTIVITY
#   ZENITY_ICON_ARG
#   ZENITY_HEIGHT (optional)
#   ZENITY_WIDTH (optional)
#   QUESTION_SYMBOL
# ARGUMENTS:
# 	The text to display
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if yes, 1 if no
#######################################
function yesno() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  _calculate-gui-title
  TEST_STRING="${QUESTION_SYMBOL}$1"
  _calculate-tui-size

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "${QUESTION_SYMBOL}$1" "$RECMD_LINES" "$RECMD_COLS"
    answer=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "${QUESTION_SYMBOL}$1" "$RECMD_LINES" "$RECMD_COLS"
    answer=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --question --text "$1"
    answer=$?
    # Exit if cancelled (zenity returns 5 for timeout, -1/255 for cancel/close)
    if [ $answer -gt 1 ]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --yesno "$1"
    answer=$?
    # Exit if cancelled (kdialog returns values > 1 for cancel/error)
    if [ $answer -gt 1 ]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  else
    echo -ne "${QUESTION_SYMBOL}${bold}$1 (y/n): ${normal}" 3>&1 1>&2 2>&3
    read -r answer
    if [ "$answer" == "y" ]; then
      answer=0
    else
      answer=1
    fi
  fi

  return $answer
}


#######################################
# Display the contents of a file
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_DOCUMENT
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
# 	The file whose text to display
# 	width of GUI display (512 if omitted)
# 	height of GUI display (640 if omitted)
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function display-file() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_DOCUMENT
  fi
  _calculate-gui-title
  TEST_STRING="$(cat "$1")"
  local width=${2-${ZENITY_WIDTH-512}}
  local height=${3-${ZENITY_HEIGHT-640}}
  _calculate-tui-size

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" "$RECMD_LINES" "$RECMD_COLS"
    exit_status=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --textbox "$1" "$RECMD_LINES" "$RECMD_COLS"
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --height="$height" --width="$width" --text-info --filename="$1"
    exit_status=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --textbox "$1" "$width" "$height"
    exit_status=$?
  else
    less "$1" 3>&1 1>&2 2>&3
    exit_status=$?
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi
}
