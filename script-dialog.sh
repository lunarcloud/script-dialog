#!/usr/bin/env bash
# Multi-UI Scripting
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Disable this rule, as it interferes with purely-numeric parameters
# shellcheck disable=SC2046

################################
# Do auto-detections at the top
################################

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
ZENITY_ICON_ARG=--icon
if command -v >/dev/null zenity && printf "%s\n4.0.0\n" "$(zenity --version)" | sort -C; then
  # this version is older than 4.0.0
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
NO_READ_DEFAULT="-r"
if echo "test" | read -ri "test" 2>/dev/null; then
  NO_READ_DEFAULT=""
fi


################################
# Variables
################################

APP_NAME="Script"
ACTIVITY=""
GUI_TITLE="$APP_NAME"

MIN_LINES=10
MIN_COLS=40
MAX_LINES=$MIN_LINES
MAX_COLS=$MIN_COLS
RECMD_LINES=10
RECMD_COLS=40
RECMD_SCROLL=false
TEST_STRING=""

#standard window icons
XDG_ICO_INFO="dialog-information"
XDG_ICO_QUESTION="dialog-question"
XDG_ICO_WARN="dialog-warning"
XDG_ICO_ERROR="dialog-error"
XDG_ICO_FOLDER_OPEN="folder-open"
XDG_ICO_FILE_OPEN="document-open"
XDG_ICO_SAVE="document-save"
XDG_ICO_PASSWORD="dialog-password"
XDG_ICO_CALENDAR="x-office-calendar"
XDG_ICO_DOCUMENT="x-office-document"

# see if it supports colors...
ncolors=$(tput colors)
if [ "$NOCOLORS" == "" ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  bold="$(tput bold)"
  underline="$(tput smul)"
  #standout="$(tput smso)"
  normal="$(tput sgr0)"
  red="$(tput setaf 1)"
  #green="$(tput setaf 2)"
  yellow="$(tput setaf 3)"
  #blue="$(tput setaf 4)"
  #magenta="$(tput setaf 5)"
  #cyan="$(tput setaf 6)"
else
  bold=""
  underline=""
  normal=""
  red=""
  yellow=""
fi

# see if we have unicode symbols support
if [ "$NOSYMBOLS" == "" ] && [[ $LANG == *UTF-8* ]]; then
  INFO_SYMBOL="ⓘ  "
  WARN_SYMBOL="⚠️  "
  ERR_SYMBOL="⛔  "
  QUESTION_SYMBOL="❓  "
  PASSWORD_SYMBOL="🔑  "
  CALENDAR_SYMBOL="📅  "
  DOCUMENT_SYMBOL="🗎  "
  FOLDER_SYMBOL="🗀  "
  HOURGLASS_SYMBOL="⌛  "
else
  INFO_SYMBOL="[i]  "
  WARN_SYMBOL="[!]  "
  ERR_SYMBOL="[!]  "
  QUESTION_SYMBOL="[?]  "
  PASSWORD_SYMBOL="[?]  "
  CALENDAR_SYMBOL=""
  DOCUMENT_SYMBOL=""
  FOLDER_SYMBOL=""
  HOURGLASS_SYMBOL=""
fi

#######################################
# Attempts to run a privileged command (sudo or equivalent)
# GLOBALS:
# 	NO_SUDO
#   SUDO
#   ACTIVITY
# ARGUMENTS:
# 	Command to run with elevated priviledge
# OUTPUTS:
# 	n/a
# RETURN:
# 	0 if success, non-zero otherwise.
#######################################
function superuser() {
  if [ $NO_SUDO == true ]; then
    (>&2 echo "${red}No sudo available!${normal}")
    return 201
  fi

  if [ $SUDO_USE_INTERFACE == true ]; then
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
    GUI_TITLE="$ACTIVITY - $APP_NAME"
  else
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
    RECMD_COLS=$MIN_COLS
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
    RECMD_SCROLL=true
  fi
  if [ "$RECMD_COLS" -gt "$MAX_COLS" ]; then
    RECMD_COLS=$MAX_COLS
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
    if whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yes-button "Continue" --no-button "Quit" --yesno "${QUESTION_SYMBOL}$MESSAGE" "$RECMD_LINES" "$RECMD_COLS"; then
      return 0
    else
      exit 0
    fi
  elif [ "$INTERFACE" == "dialog" ]; then
    if dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yes-label "Continue" --no-label "Quit" --yesno "${QUESTION_SYMBOL}$MESSAGE" "$RECMD_LINES" "$RECMD_COLS"; then
      return 0
    else
      exit 0
    fi
  elif [ "$INTERFACE" == "zenity" ]; then
    if zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --question --text "$MESSAGE" --ok-label="Continue" --cancel-label="Quit"; then
      return 0
    else
      exit 0
    fi
  elif [ "$INTERFACE" == "kdialog" ]; then
    if kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --yes-label "Continue" --no-label "Quit" --yesno "$MESSAGE"; then
      return 0
    else
      exit 0
    fi
  else
    echo -ne "${QUESTION_SYMBOL}${bold}$MESSAGE (press Enter to continue, q to quit): ${normal}" 3>&1 1>&2 2>&3
    read -r answer
    if [[ "${answer,,}" == "q" ]]; then
      exit 0
    fi
    return 0
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
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --yesno "$1"
    answer=$?
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

  if [ "$INTERFACE" == "whiptail" ]; then
    INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_LINES" "$RECMD_COLS" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_LINES" "$RECMD_COLS" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT="$(zenity --entry --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --text="$1" --entry-text "$2")"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT="$(kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --inputbox "$1" "$2")"
  else
    read ${NO_READ_DEFAULT+-i "$2"} -rep "${SYMBOL}${bold}$1: ${normal}" INPUT
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
    CREDS[0]=$(echo "$ENTRY" | cut -d'|' -f1)
    CREDS[1]=$(echo "$ENTRY" | cut -d'|' -f2)
  elif [ "$INTERFACE" == "kdialog" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$PASS_TEXT")
  else
    read ${NO_READ_DEFAULT+-i "$SUGGESTED_USERNAME"} -rep "${QUESTION_SYMBOL}${bold}$USER_TEXT: ${normal}" "CREDS[0]"
    read -srp "${bold}${PASSWORD_SYMBOL}$PASS_TEXT: ${normal}" "CREDS[1]"
    echo
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

  if [ "$INTERFACE" == "whiptail" ]; then
    PASSWORD=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_LINES" "$RECMD_COLS" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    PASSWORD=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_LINES" "$RECMD_COLS" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    PASSWORD=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --password)
  elif [ "$INTERFACE" == "kdialog" ]; then
    PASSWORD=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$1")
  else
    read -srp "${PASSWORD_SYMBOL}${bold}$ACTIVITY: ${normal}" PASSWORD
  fi
  echo "$PASSWORD"
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

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --textbox "$1" "$RECMD_LINES" "$RECMD_COLS"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --height="$height" --width="$width" --text-info --filename="$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --textbox "$1" "$width" "$height"
  else
    less "$1" 3>&1 1>&2 2>&3
  fi
}

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

  if [ "$INTERFACE" == "whiptail" ]; then
    mapfile -t CHOSEN_ITEMS < <( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --checklist "${QUESTION_SYMBOL}$TEXT" $RECMD_LINES $RECMD_COLS "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    IFS=$'\n' read -r -d '' -a CHOSEN_LIST < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --separate-output --checklist "${QUESTION_SYMBOL}$TEXT" $RECMD_LINES $RECMD_COLS "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)

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
    IFS=$'|' read -r -d '' -a CHOSEN_LIST < <( zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --height="${ZENITY_HEIGHT-512}" ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --list --text "$TEXT" --checklist --column "" --column "Value" --column "Description" "${OPTIONS[@]}" )

    local CHOSEN_ITEMS=()
    for value in "${CHOSEN_LIST[@]}"
    do
      CHOSEN_ITEMS+=( "\"$value\"" )
    done

  elif [ "$INTERFACE" == "kdialog" ]; then
    mapfile -t CHOSEN_ITEMS < <( kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --checklist "$TEXT" "$@")
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

  if [ "$INTERFACE" == "whiptail" ]; then
    CHOSEN_ITEM=$( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "${QUESTION_SYMBOL}$TEXT" $RECMD_LINES $RECMD_COLS "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    CHOSEN_ITEM=$( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --quoted --radiolist "${QUESTION_SYMBOL}$TEXT" $RECMD_LINES $RECMD_COLS "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
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
    CHOSEN_ITEM=$( zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --height="${ZENITY_HEIGHT-512}" ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --list --text "$TEXT" --radiolist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")
  elif [ "$INTERFACE" == "kdialog" ]; then
    CHOSEN_ITEM=$( kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --radiolist "$TEXT" "$@")
  else
    echo -e "${QUESTION_SYMBOL}$ACTIVITY: " 3>&1 1>&2 2>&3
    OPTIONS=()
    local DEFAULT=""
    while test ${#} -gt 0;  do
      local DEFAULT_NOTATION=""
      if [ "$3" == "ON" ]; then
        local DEFAULT+="\"$1\""
        local DEFAULT_NOTATION="*"
      fi
      OPTIONS+=("\t- ${underline}$1${normal}$DEFAULT_NOTATION ($2)\n")
      shift
      shift
      shift
    done
    read -rp "$(echo -e "${OPTIONS[*]}${QUESTION_SYMBOL}${bold}$TEXT: ${normal}")" CHOSEN_ITEM

    if [[ "$CHOSEN_ITEM" == "" ]]; then
      CHOSEN_ITEM="$DEFAULT"
    fi
  fi

  echo "$CHOSEN_ITEM"
}


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
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2012
    read -r -d '' -a files < <(ls -lBhpa "$1" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_LINES)) $((6+RECMD_COLS)) $RECMD_LINES "${files[@]}" 3>&1 1>&2 2>&3)
    FILE="$1/$SELECTED"

    #exitstatus=$?
    #if [ $exitstatus != 0 ]; then
        #echo "CANCELLED!"
        #exit;
    #fi

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --fselect "$1"/ 14 48)
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --file-selection --filename "$1"/ )
  elif [ "$INTERFACE" == "kdialog" ]; then
    if [ "$2" == "save" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getsavefilename "$1"/ )
    else #elif [ "$2" == "open" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getopenfilename "$1"/ )
    fi
  else
    read -erp "${DOCUMENT_SYMBOL}You need to $2 a file in $1/. Hit enter to browse this folder"

    ls -lBhpa "$1" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED

    # TODO: Add validation - handle empty SELECTED or when SELECTED is a folder

    FILE=$1/$SELECTED
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
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2010
    read -r -d '' -a files < <(ls -lBhpa "$1" | grep "^d" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_LINES)) $((6+RECMD_COLS)) $RECMD_LINES "${files[@]}" 3>&1 1>&2 2>&3)
    FILE="$1/$SELECTED"

    #exitstatus=$?
    #if [ $exitstatus != 0 ]; then
        #echo "CANCELLED!"
        #exit;
    #fi

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --dselect "$1"/ 14 48)
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --file-selection --directory --filename "$1"/ )
  elif [ "$INTERFACE" == "kdialog" ]; then
    FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getexistingdirectory "$1"/ )
  else
    read -erp "${FOLDER_SYMBOL}You need to select a folder in $1/. Hit enter to browse this folder"

    # shellcheck disable=SC2010
    ls -lBhpa "$1" | grep "^d" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED

    # TODO: Add validation - handle empty SELECTED or parent directory (..)

    FILE=$1/$SELECTED
  fi

  echo "$FILE"
}


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

  if [ "$INTERFACE" == "whiptail" ]; then
    local SYMBOL=$CALENDAR_SYMBOL
    STANDARD_DATE=$(inputbox "Input Date (DD/MM/YYYY)" "$NOW")
  elif [ "$INTERFACE" == "dialog" ]; then
    STANDARD_DATE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --calendar "${CALENDAR_SYMBOL}Choose Date" 0 40)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT_DATE=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" ${ZENITY_HEIGHT+--height=$ZENITY_HEIGHT} ${ZENITY_WIDTH+--width=$ZENITY_WIDTH} --calendar "Select Date")
    MONTH=$(echo "$INPUT_DATE" | cut -d'/' -f1)
    DAY=$(echo "$INPUT_DATE" | cut -d'/' -f2)
    YEAR=$(echo "$INPUT_DATE" | cut -d'/' -f3)
    STANDARD_DATE="$DAY/$MONTH/$YEAR"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT_DATE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --calendar "Select Date")
    TEXT_MONTH=$(echo "$INPUT_DATE" | cut -d' ' -f2)
    if [ "$TEXT_MONTH" == "Jan" ]; then
      MONTH=1
    elif [ "$TEXT_MONTH" == "Feb" ]; then
      MONTH=2
    elif [ "$TEXT_MONTH" == "Mar" ]; then
      MONTH=3
    elif [ "$TEXT_MONTH" == "Apr" ]; then
      MONTH=4
    elif [ "$TEXT_MONTH" == "May" ]; then
      MONTH=5
    elif [ "$TEXT_MONTH" == "Jun" ]; then
      MONTH=6
    elif [ "$TEXT_MONTH" == "Jul" ]; then
      MONTH=7
    elif [ "$TEXT_MONTH" == "Aug" ]; then
      MONTH=8
    elif [ "$TEXT_MONTH" == "Sep" ]; then
      MONTH=9
    elif [ "$TEXT_MONTH" == "Oct" ]; then
      MONTH=10
    elif [ "$TEXT_MONTH" == "Nov" ]; then
      MONTH=11
    else #elif [ "$TEXT_MONTH" == "Dec" ]; then
      MONTH=12
    fi

    DAY=$(echo "$INPUT_DATE" | cut -d' ' -f3)
    YEAR=$(echo "$INPUT_DATE" | cut -d' ' -f4)
    STANDARD_DATE="$DAY/$MONTH/$YEAR"
  else
    read ${NO_READ_DEFAULT+-i "$NOW"} -rep "${CALENDAR_SYMBOL}${bold}Date (DD/MM/YYYY): ${normal}" STANDARD_DATE
  fi

  echo "$STANDARD_DATE"
}
