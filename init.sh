#!/usr/bin/env bash
# Multi-UI Scripting - Initialization
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Disable SC2034 for the entire file as variables defined here are used by scripts that source this library
# shellcheck disable=SC2034

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

# Set default cancel exit code if not already set
if [ -z "${SCRIPT_DIALOG_CANCEL_EXIT_CODE+x}" ]; then
  SCRIPT_DIALOG_CANCEL_EXIT_CODE=124
fi


################################
# Variables
################################

# These variables are intentionally exposed for use by scripts that source this library
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
if command -v tput >/dev/null 2>&1; then
  ncolors=$(tput colors 2>/dev/null)
else
  ncolors=""
fi

if [ "$NOCOLORS" == "" ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  bold="$(tput bold 2>/dev/null)"
  underline="$(tput smul 2>/dev/null)"
  #standout="$(tput smso 2>/dev/null)"
  normal="$(tput sgr0 2>/dev/null)"
  red="$(tput setaf 1 2>/dev/null)"
  #green="$(tput setaf 2 2>/dev/null)"
  yellow="$(tput setaf 3 2>/dev/null)"
  #blue="$(tput setaf 4 2>/dev/null)"
  #magenta="$(tput setaf 5 2>/dev/null)"
  #cyan="$(tput setaf 6 2>/dev/null)"
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
