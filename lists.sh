#!/usr/bin/env bash
# Multi-UI Scripting - List Selection Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Variables set in init.sh and used here
# shellcheck disable=SC2034  # line variable in read loops
# shellcheck disable=SC2154

#######################################
# Display a list of multiply-selectable items
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_QUESTION
#   QUESTION_SYMBOL
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
# 	The file whose text to display
#   Number of options
#   First item's value
#   First item's description
#   First item's default checked status (ON or OFF)
#   (repeat $3, $4, $5 for all items)
# OUTPUTS:
# 	Array of selected items
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function checklist() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  _calculate-gui-title
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  _calculate-tui-size
  
  # Adjust height to account for the number of options
  # Each option takes 1 line, plus we need space for prompt and UI elements
  local needed_lines=$((NUM_OPTIONS + 6))  # 6 lines for prompt, borders, and buttons
  
  # Dialog interface displays the text in the body, whiptail shows it in the title
  # Add extra lines for dialog to show the message text
  if [ "$INTERFACE" == "dialog" ]; then
    local text_lines=0
    while IFS= read -r line; do
      text_lines=$((text_lines + 1))
    done <<< "$TEXT"
    needed_lines=$((needed_lines + text_lines))
  fi
  
  if [ "$needed_lines" -gt "$RECMD_LINES" ]; then
    RECMD_LINES=$needed_lines
    # Enforce maximum constraint
    if [ "$RECMD_LINES" -gt "$MAX_LINES" ]; then
      RECMD_LINES=$MAX_LINES
      RECMD_SCROLL=true
    fi
  fi

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2046  # Intentional word splitting for conditional argument
    mapfile -t CHOSEN_ITEMS < <( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --checklist "${QUESTION_SYMBOL}$TEXT" "$RECMD_LINES" "$RECMD_COLS" "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
    exit_status=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    local DIALOG_OUTPUT
    # shellcheck disable=SC2046  # Intentional word splitting for conditional argument
    DIALOG_OUTPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --separate-output --checklist "${QUESTION_SYMBOL}$TEXT" "$RECMD_LINES" "$RECMD_COLS" "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
    exit_status=$?
    IFS=$'\n' read -r -d '' -a CHOSEN_LIST < <( echo "${DIALOG_OUTPUT[@]}" )

    local CHOSEN_ITEMS=()
    for value in "${CHOSEN_LIST[@]}"
    do
      CHOSEN_ITEMS+=( "\"$value\"" )
    done

  elif [ "$INTERFACE" == "zenity" ]; then
    OPTIONS=()
    while test ${#} -gt 0;  do
      if [ "$3" == "ON" ]; then
        OPTIONS+=("TRUE")
      else
        OPTIONS+=("FALSE")
      fi
      OPTIONS+=("$1")
      OPTIONS+=("$2")
      shift
      shift
      shift
    done
    local ZENITY_OUTPUT
    ZENITY_OUTPUT=$(zenity --title "$GUI_TITLE" "$ZENITY_ICON_ARG" "$GUI_ICON" --height="${ZENITY_HEIGHT-512}" ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --list --text "$TEXT" --checklist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")
    exit_status=$?
    IFS=$'|' read -r -d '' -a CHOSEN_LIST < <( echo "$ZENITY_OUTPUT" )

    local CHOSEN_ITEMS=()
    for value in "${CHOSEN_LIST[@]}"
    do
      CHOSEN_ITEMS+=( "\"$value\"" )
    done

  elif [ "$INTERFACE" == "kdialog" ]; then
    mapfile -t CHOSEN_ITEMS < <( kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --checklist "$TEXT" "$@")
    exit_status=$?
  else
    printf "%s\n $TEXT:\n" "${QUESTION_SYMBOL}$ACTIVITY" 3>&1 1>&2 2>&3
    local CHOSEN_ITEMS=()
    while test ${#} -gt 0; do
      if yesno "$2 (default: $3)?"; then
        CHOSEN_ITEMS+=( "\"$1\"" )
      elif [ "$3" == "ON" ]; then
        CHOSEN_ITEMS+=( "\"$1\"" )
      fi
      shift
      shift
      shift
    done
  fi

  # Exit script if dialog was cancelled
  if [ $exit_status -ne 0 ]; then
    exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
  fi

  echo "${CHOSEN_ITEMS[@]}"
}


#######################################
# Display a list of singularly-selectable items
# GLOBALS:
# 	GUI_ICON
#   GUI_TITLE
#   XDG_ICO_QUESTION
#   QUESTION_SYMBOL
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
# 	The file whose text to display
#   Number of options
#   First item's value
#   First item's description
#   First item's default selected status (ON or OFF)
#   (repeat $3, $4, $5 for all items)
# OUTPUTS:
# 	Value text of the selected item (or the default item)
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function radiolist() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  _calculate-gui-title
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  _calculate-tui-size
  
  # Adjust height to account for the number of options
  # Each option takes 1 line, plus we need space for prompt and UI elements
  local needed_lines=$((NUM_OPTIONS + 6))  # 6 lines for prompt, borders, and buttons
  
  # Dialog interface displays the text in the body, whiptail shows it in the title
  # Add extra lines for dialog to show the message text
  if [ "$INTERFACE" == "dialog" ]; then
    local text_lines=0
    while IFS= read -r line; do
      text_lines=$((text_lines + 1))
    done <<< "$TEXT"
    needed_lines=$((needed_lines + text_lines))
  fi
  
  if [ "$needed_lines" -gt "$RECMD_LINES" ]; then
    RECMD_LINES=$needed_lines
    # Enforce maximum constraint
    if [ "$RECMD_LINES" -gt "$MAX_LINES" ]; then
      RECMD_LINES=$MAX_LINES
      RECMD_SCROLL=true
    fi
  fi

  local exit_status=0
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2046  # Intentional word splitting for conditional argument
    CHOSEN_ITEM=$( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "${QUESTION_SYMBOL}$TEXT" "$RECMD_LINES" "$RECMD_COLS" "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
    exit_status=$?
    # For TUI interfaces, empty response indicates cancel
    if [ $exit_status -ne 0 ] || [[ -z "$CHOSEN_ITEM" ]]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  elif [ "$INTERFACE" == "dialog" ]; then
    # shellcheck disable=SC2046  # Intentional word splitting for conditional argument
    CHOSEN_ITEM=$( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "${QUESTION_SYMBOL}$TEXT" "$RECMD_LINES" "$RECMD_COLS" "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
    exit_status=$?
    # For TUI interfaces, empty response indicates cancel
    if [ $exit_status -ne 0 ] || [[ -z "$CHOSEN_ITEM" ]]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  elif [ "$INTERFACE" == "zenity" ]; then
    OPTIONS=()
    while test ${#} -gt 0;  do
      if [ "$3" == "ON" ]; then
        OPTIONS+=("TRUE")
      else
        OPTIONS+=("FALSE")
      fi
      OPTIONS+=("$1")
      OPTIONS+=("$2")
      shift
      shift
      shift
    done
    CHOSEN_ITEM=$( zenity --title "$GUI_TITLE" "$ZENITY_ICON_ARG" "$GUI_ICON" --height="${ZENITY_HEIGHT-512}" ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --list --text "$TEXT" --radiolist --column "" --column "Value" --column "Description" "${OPTIONS[@]}" 2>/dev/null)
    exit_status=$?
    # For GUI interfaces, empty response indicates cancel
    if [ $exit_status -ne 0 ] || [[ -z "$CHOSEN_ITEM" ]]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  elif [ "$INTERFACE" == "kdialog" ]; then
    CHOSEN_ITEM=$( kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --radiolist "$TEXT" "$@")
    exit_status=$?
    # For GUI interfaces, empty response indicates cancel
    if [ $exit_status -ne 0 ] || [[ -z "$CHOSEN_ITEM" ]]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  else
    echo -e "${QUESTION_SYMBOL}$ACTIVITY: " 3>&1 1>&2 2>&3
    OPTIONS=()
    local DEFAULT=""
    while test ${#} -gt 0;  do
      local DEFAULT_NOTATION=""
      if [ "$3" == "ON" ]; then
        DEFAULT+="\"$1\""
        DEFAULT_NOTATION="*"
      fi
      OPTIONS+=("\t- ${underline}$1${normal}$DEFAULT_NOTATION ($2)\n")
      shift
      shift
      shift
    done
    read -rp "$(echo -e "${OPTIONS[*]}${QUESTION_SYMBOL}${bold}$TEXT: ${normal}")" CHOSEN_ITEM
    exit_status=$?

    if [[ "$CHOSEN_ITEM" == "" ]]; then
      CHOSEN_ITEM="$DEFAULT"
    fi
    
    # For CLI interface, only check exit status
    if [ $exit_status -ne 0 ]; then
      exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"
    fi
  fi

  echo "$CHOSEN_ITEM"
}
