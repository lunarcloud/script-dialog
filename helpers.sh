#!/usr/bin/env bash
# Multi-UI Scripting - Helper Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Variables set in init.sh and used here
# shellcheck disable=SC2154

#######################################
# Attempts to run a privileged command (sudo or equivalent)
# GLOBALS:
# 	NO_SUDO
#   SUDO
#   ACTIVITY
# ARGUMENTS:
# 	Command to run with elevated privilege
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function superuser() {
  if [ "$NO_SUDO" == true ]; then
    (>&2 echo "${red}No sudo available!${normal}")
    return 201
  fi

  if [ "$SUDO_USE_INTERFACE" == true ]; then
    ACTIVITY="Enter password to run \"$*\""
    password "$@" | sudo -p "" -S -- "$@"
  elif [[ "$SUDO" == *"pkexec"* ]]; then
    $SUDO "$@"
  elif sudo -n true 2>/dev/null; then # if credentials cached
    sudo -- "$@"
  else
    $SUDO -- "$@"
  fi
}


#######################################
# Set the GUI_TITLE based on the ACTIVITY and APP_NAME
# GLOBALS:
# 	GUI_TITLE
#   ACTIVITY
#   APP_NAME
# ARGUMENTS:
# 	n/a
# OUTPUTS:
# 	n/a
# RETURN:
# 	n/a
#######################################
function _calculate-gui-title() {
  if [ -n "$ACTIVITY" ]; then
    # shellcheck disable=SC2034  # GUI_TITLE is used by other functions
    GUI_TITLE="$ACTIVITY - $APP_NAME"
  else
    # shellcheck disable=SC2034
    GUI_TITLE="$APP_NAME"
  fi
}


#######################################
# Update the max columns & lines
# GLOBALS:
# 	GUI
#   MAX_COLS
#   MAX_LINES
# ARGUMENTS:
# 	n/a
# OUTPUTS:
# 	n/a
# RETURN:
# 	n/a
#######################################
function _calculate-tui-max() {
  if ! command -v >/dev/null tput; then
    return;
  fi

  if [ "$GUI" == "false" ] ; then
    MAX_LINES=$(tput lines)
    MAX_COLS=$(tput cols)
  fi

  # Never really fill the whole screen space
  MAX_LINES=$(( MAX_LINES - 5 ))
  MAX_COLS=$(( MAX_COLS - 4 ))
}


#######################################
# Update the recommended columns, lines, scroll
# GLOBALS:
# 	TEST_STRING
#   RECMD_SCROLL
#   RECMD_COLS
#   RECMD_LINES
#   MAX_COLS
#   MAX_LINES
#   MIN_COLS
#   MIN_LINES
# ARGUMENTS:
# 	n/a
# OUTPUTS:
# 	n/a
# RETURN:
# 	n/a
#######################################
function _calculate-tui-size() {
  _calculate-tui-max
  RECMD_SCROLL=false
  
  # Handle empty string case
  if [ -z "$TEST_STRING" ]; then
    # shellcheck disable=SC2153  # MIN_COLS and MIN_LINES are defined in init.sh
    RECMD_COLS=$MIN_COLS
    # shellcheck disable=SC2153
    RECMD_LINES=$MIN_LINES
    return
  fi
  
  # Count actual lines and find longest line
  local line_count=0
  local max_line_length=0
  
  while IFS= read -r line; do
    line_count=$((line_count + 1))
    local line_len=${#line}
    if [ "$line_len" -gt "$max_line_length" ]; then
      max_line_length=$line_len
    fi
  done <<< "$TEST_STRING"
  
  # Calculate recommended columns based on longest line
  # Add padding for borders, margins, and UI elements (typically 4-6 chars)
  RECMD_COLS=$((max_line_length + 6))
  
  # For single-line text, consider wrapping and use a reasonable width
  if [ "$line_count" -eq 1 ]; then
    local total_chars=${#TEST_STRING}
    
    # Target width: Start with content + padding, but cap at a reasonable maximum
    # Use 50% of available space as the maximum for single-line text
    local target_width=$((MAX_COLS / 2))
    if [ "$target_width" -lt "$MIN_COLS" ]; then
      target_width=$MIN_COLS
    fi
    
    # Only expand to target width if text is long enough to benefit from it
    # For short text, stay closer to content size
    if [ "$RECMD_COLS" -lt "$target_width" ] && [ "$total_chars" -gt 40 ]; then
      RECMD_COLS=$target_width
    fi
    
    # Calculate wrapped line count at this width
    # Subtract padding to get actual text width
    local text_width=$((RECMD_COLS - 6))
    # Ensure text_width is at least 1 to avoid division by zero
    if [ "$text_width" -le 0 ]; then
      text_width=1
    fi
    # Calculate ceiling division: (total_chars + text_width - 1) / text_width
    line_count=$(((total_chars + text_width - 1) / text_width))
  fi
  
  # Calculate recommended lines with padding for UI elements
  # Add 4 lines for title, borders, and buttons
  RECMD_LINES=$((line_count + 4))
  
  # Enforce maximum constraints
  if [ "$RECMD_LINES" -gt "$MAX_LINES" ] ; then
    RECMD_LINES=$MAX_LINES
    # shellcheck disable=SC2034  # RECMD_SCROLL is used by dialog functions
    RECMD_SCROLL=true
  fi
  if [ "$RECMD_COLS" -gt "$MAX_COLS" ]; then
    RECMD_COLS=$MAX_COLS
    # shellcheck disable=SC2034
    RECMD_SCROLL=true
  fi

  # Enforce minimum constraints
  if [ "$RECMD_LINES" -lt "$MIN_LINES" ] ; then
    RECMD_LINES=$MIN_LINES
  fi
  if [ "$RECMD_COLS" -lt "$MIN_COLS" ]; then
    RECMD_COLS=$MIN_COLS
  fi

  TEST_STRING="" #blank out for memory's sake
}

#######################################
# if neither GUI nor terminal interfaces can be used, relaunch the script in a terminal emulator
# GLOBALS:
# 	GUI
#   terminal
# ARGUMENTS:
# 	n/a
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function relaunch-if-not-visible() {
  local parentScript
  parentScript=$(basename "$0")

  if [ "$GUI" == "false" ] && [ "$terminal" == "false" ]; then
    if [ -e "/tmp/relaunching" ] && [ "$(cat /tmp/relaunching)" == "$parentScript" ]; then
      echo "Won't relaunch $parentScript more than once"
    else
      echo "$parentScript" > /tmp/relaunching

      echo "Relaunching $parentScript ..."

      local TERM_APP=xterm
      # Launch in whatever terminal is available
      if command -v >/dev/null x-terminal-emulator; then
        TERM_APP=x-terminal-emulator
      elif [ "$desktop" != "gnome" ] && command -v >/dev/null kdialog; then
        TERM_APP=kdialog
      elif [ "$desktop" != "kde" ] && command -v >/dev/null gnome-terminal; then
        TERM_APP=gnome-terminal
      elif command -v >/dev/null xfce4-terminal; then
        TERM_APP=xfce4-terminal
      elif command -v >/dev/null qterminal; then
        TERM_APP=qterminal
      fi
      $TERM_APP -e "./$parentScript"
      rm /tmp/relaunching
      exit $?;
    fi
  fi
}
