#!/usr/bin/env bash
# Multi-UI Scripting - Helper Functions
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Variables set in init.sh and used here
# shellcheck disable=SC2154

#######################################
# Detect or re-detect the environment and available dialog tools
# This function can be called to re-run environment detection,
# useful when switching contexts (e.g., from CI to interactive)
# GLOBALS:
#   DETECTED_DESKTOP - Set to detected desktop environment
#   desktop - Internal variable for desktop environment
#   terminal - Set to true if running in terminal
#   GUI - Set to true if GUI is available (unless pre-set by user)
#   INTERFACE - Set to best available dialog interface (unless pre-set by user)
#   hasKDialog, hasZenity, hasDialog, hasWhiptail - Set based on available tools
#   NO_SUDO, SUDO, SUDO_USE_INTERFACE - Set based on available privilege elevation
#   NO_READ_DEFAULT - Set based on read command capabilities
#   ZENITY_ICON_ARG - Set based on zenity version
# ARGUMENTS:
#   None
# OUTPUTS:
#   None
# RETURN:
#   0 always
#######################################
function detect_environment() {
  # Detect desktop environment for optimal dialog selection
  # Priority: OS type -> XDG variables -> running processes
  
  if [[ $OSTYPE == darwin* ]]; then
      desktop="macos"
  elif [[ $OSTYPE == msys ]] || [[ $(uname -r | tr '[:upper:]' '[:lower:]') == *wsl* ]]; then
      desktop="windows"
  elif [ -n "$XDG_CURRENT_DESKTOP" ]; then
    # shellcheck disable=SC2001
    desktop=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]' | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
  elif [ -n "$XDG_SESSION_DESKTOP" ]; then
    # shellcheck disable=SC2001
    desktop=$(echo "$XDG_SESSION_DESKTOP" | tr '[:upper:]' '[:lower:]' | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
  elif command -v >/dev/null pgrep && pgrep -l "gnome-shell" > /dev/null; then
      desktop="gnome"
  elif command -v >/dev/null pgrep && pgrep -l "mutter" > /dev/null; then
      desktop="gnome"
  elif command -v >/dev/null pgrep && pgrep -l "kwin" > /dev/null; then
      desktop="kde"
  else
    desktop="unknown"
  fi
  
  # Ensure lowercase for consistent comparisons (redundant for some paths above)
  desktop=$(echo "$desktop" | tr '[:upper:]' '[:lower:]')
  export DETECTED_DESKTOP=$desktop
  
  # If we have a standard in and out, then terminal
  [ -t 0 ] && [ -t 1 ] && terminal=true || terminal=false
  
  # Initialize dialog tool availability flags
  
  hasKDialog=false
  hasZenity=false
  hasDialog=false
  hasWhiptail=false
  
  # Determine if GUI is available (unless already set)
  if [ -z ${GUI+x} ]; then
    GUI=false
    if [ "$terminal" == "false" ] ; then
      GUI=$([ "$DISPLAY" ] || [ "$WAYLAND_DISPLAY" ] || [ "$MIR_SOCKET" ] && echo true || echo false)
    fi
  fi
  
  # Check which dialog tools are available
  
  if command -v >/dev/null kdialog; then
    hasKDialog=true
  fi
  
  if command -v >/dev/null zenity; then
    hasZenity=true
  fi
  
  if command -v >/dev/null dialog; then
    hasDialog=true
  fi
  
  if command -v >/dev/null whiptail; then
    hasWhiptail=true
  fi
  
  # Auto-select the best available dialog interface based on desktop environment
  if [ -z ${INTERFACE+x} ]; then
    if [ "$desktop" == "kde" ] || [ "$desktop" == "razor" ]  || [ "$desktop" == "lxqt" ]  || [ "$desktop" == "maui" ] ; then
      if  [ "$hasKDialog" == "true" ] && [ "$GUI" == "true" ] ; then
        INTERFACE="kdialog"
        GUI=true
      elif [ "$hasZenity" == "true" ] && [ "$GUI" == "true" ] ; then
        INTERFACE="zenity"
        GUI=true
      elif  [ "$hasDialog" == "true" ] ; then
        INTERFACE="dialog"
        GUI=false
      elif  [ "$hasWhiptail" == "true" ] ; then
        INTERFACE="whiptail"
        GUI=false
      fi
    elif [ "$desktop" == "unity" ] || [ "$desktop" == "gnome" ]  || [ "$desktop" == "xfce" ]  || [ -n "$INTERFACE" ]; then
      if [ "$hasZenity" == "true" ] && [ "$GUI" == "true" ] ; then
        INTERFACE="zenity"
        GUI=true
      elif  [ "$hasDialog" == "true" ] ; then
        INTERFACE="dialog"
        GUI=false
      elif  [ "$hasWhiptail" == "true" ] ; then
        INTERFACE="whiptail"
        GUI=false
      fi
    else
      if  [ "$hasDialog" == "true" ] ; then
        INTERFACE="dialog"
        GUI=false
      elif  [ "$hasWhiptail" == "true" ] ; then
        INTERFACE="whiptail"
        GUI=false
      fi
    fi
  fi
  
  # Handle Zenity major version difference
  # shellcheck disable=SC2034  # ZENITY_ICON_ARG is used by message and input functions
  ZENITY_ICON_ARG=--icon
  if command -v >/dev/null zenity && printf "%s\n4.0.0\n" "$(zenity --version)" | sort -C; then
    # this version is older than 4.0.0
    # shellcheck disable=SC2034
    ZENITY_ICON_ARG=--icon-name
  fi
  
  if  [ "$INTERFACE" == "kdialog" ] || [ "$INTERFACE" == "zenity" ] ; then
    GUI=true
  fi
  
  # Select the best available sudo/privilege elevation method
  NO_SUDO=false
  SUDO_USE_INTERFACE=false
  if [ "$GUI" == "true" ] &&  command -v >/dev/null pkexec; then
    SUDO="pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY"
  elif [ "$INTERFACE" == "kdialog" ] && command -v >/dev/null gksudo; then
    SUDO="kdesudo"
  elif [ "$GUI" == "true" ] && command -v >/dev/null gksudo; then
    SUDO="gksudo"
  elif [ "$GUI" == "true" ] && command -v >/dev/null gksu; then
    SUDO="gksu"
  elif command -v >/dev/null sudo; then
    SUDO="sudo"
    if [ "$INTERFACE" == "whiptail" ] || [ "$INTERFACE" == "dialog" ]; then
      SUDO_USE_INTERFACE=true
    fi
  else
    NO_SUDO=true
  fi
  
  # Handle when read command doesn't support default text option
  # shellcheck disable=SC2034  # NO_READ_DEFAULT is used by input functions
  NO_READ_DEFAULT="-r"
  if echo "test" | read -ri "test" 2>/dev/null; then
    # shellcheck disable=SC2034
    NO_READ_DEFAULT=""
  fi
}

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
  if ! command -v tput >/dev/null 2>&1; then
    return;
  fi

  if [ "$GUI" == "false" ] ; then
    MAX_LINES=$(tput lines 2>/dev/null)
    MAX_COLS=$(tput cols 2>/dev/null)
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
