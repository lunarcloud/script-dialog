#!/usr/bin/env bash
# Multi-UI Scripting - Date Picker Function
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Variables set in init.sh and used here
# shellcheck disable=SC2154

#######################################
# Display a calendar date selector dialog
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_CALENDAR
#   CALENDAR_SYMBOL
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
# 	Selected date text (DD/MM/YYYY)
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################

# declare month array
declare -A month=(
    [Jan]=1 [Feb]=2 [Mar]=3 [Apr]=4
    [May]=5 [Jun]=6 [Jul]=7 [Aug]=8
    [Sep]=9 [Oct]=10 [Nov]=11 [Dec]=12
)

function datepicker() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_CALENDAR
  fi
  _calculate-gui-title

  NOW="31/12/2024"
  if [ -n "$NO_READ_DEFAULT" ]; then
    NOW=$( printf '%(%d/%m/%Y)T' )
  fi
  DAY=0
  MONTH=0
  YEAR=0

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2034  # SYMBOL used by whiptail in this context
    local SYMBOL=$CALENDAR_SYMBOL
    STANDARD_DATE=$(inputbox "Input Date (DD/MM/YYYY)" "$NOW")
  elif [ "$INTERFACE" == "dialog" ]; then
    STANDARD_DATE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --calendar "${CALENDAR_SYMBOL}Choose Date" 0 40)
    exit_status=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT_DATE=$(zenity --title="$GUI_TITLE" "$ZENITY_ICON_ARG" "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --calendar "Select Date")
    exit_status=$?
    MONTH=$(echo "$INPUT_DATE" | cut -d'/' -f1)
    DAY=$(echo "$INPUT_DATE" | cut -d'/' -f2)
    YEAR=$(echo "$INPUT_DATE" | cut -d'/' -f3)
    STANDARD_DATE="$DAY/$MONTH/$YEAR"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT_DATE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --calendar "Select Date")
    exit_status=$?
    TEXT_MONTH=$(echo "$INPUT_DATE" | cut -d' ' -f2)
    MONTH=${month["$TEXT_MONTH"]:-0}

    DAY=$(echo "$INPUT_DATE" | cut -d' ' -f3)
    YEAR=$(echo "$INPUT_DATE" | cut -d' ' -f4)
    STANDARD_DATE="$DAY/$MONTH/$YEAR"
  else
    read ${NO_READ_DEFAULT+-i "$NOW"} -rep "${CALENDAR_SYMBOL}${bold}Date (DD/MM/YYYY): ${normal}" STANDARD_DATE
    exit_status=$?
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

  echo "$STANDARD_DATE"
}
