#!/bin/bash
#multi-ui scripting

# Disable this rule, as it interferes with purely-numeric parameters
# shellcheck disable=SC2046

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


desktop=$(echo "$desktop" | tr '[:upper:]' '[:lower:]')  # convert to lower case

# If we have a standard in and out, then terminal
[ -t 0 ] && [ -t 1 ] && terminal=true || terminal=false

hasKDialog=false
hasZenity=false
hasDialog=false
hasWhiptail=false

if [ -z ${GUI+x} ]; then
  GUI=false
  if [ "$terminal" == "false" ] ; then
    GUI=$([ "$DISPLAY" ] || [ "$WAYLAND_DISPLAY" ] || [ "$MIR_SOCKET" ] && echo true || echo false)
  fi
fi

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
  INFO_SYMBOL="🛈  "
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

# Hanadle Zenity major version difference
ZENITY_ICON_ARG=--icon
if command -v >/dev/null zenity && printf "%s\n4.0.0\n" "$(zenity --version)" | sort -C; then
  # this version is older than 4.0.0
  ZENITY_ICON_ARG=--icon-name
fi

if  [ "$INTERFACE" == "kdialog" ] || [ "$INTERFACE" == "zenity" ] ; then
  GUI=true
fi

# which sudo to use
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

APP_NAME="Script"
ACTIVITY=""
GUI_TITLE="$APP_NAME"

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

function updateGUITitle() {
  if [ -n "$ACTIVITY" ]; then
    GUI_TITLE="$ACTIVITY - $APP_NAME"
  else
    GUI_TITLE="$APP_NAME"
  fi
}

MIN_HEIGHT=10
MIN_WIDTH=40
MAX_HEIGHT=$MIN_HEIGHT
MAX_WIDTH=$MIN_WIDTH

function updateDialogMaxSize() {
  if ! command -v >/dev/null tput; then
    return;
  fi

  if [ "$GUI" == "false" ] ; then
    MAX_HEIGHT=$(tput lines)
    MAX_WIDTH=$(tput cols)
  fi

  # Never really fill the whole screen space
  MAX_HEIGHT=$(( MAX_HEIGHT * 3 / 4 ))
  MAX_WIDTH=$(( MAX_WIDTH * 6 / 9 ))
}

RECMD_HEIGHT=10
RECMD_WIDTH=40
RECMD_SCROLL=false
TEST_STRING=""

function calculateTextDialogSize() {
  updateDialogMaxSize
  CHARS=${#TEST_STRING}
  RECMD_SCROLL=false
  RECMD_HEIGHT=$((CHARS  / MIN_WIDTH))
  RECMD_WIDTH=$((CHARS / MIN_HEIGHT))

  if [ "$RECMD_HEIGHT" -gt "$MAX_HEIGHT" ] ; then
    RECMD_HEIGHT=$MAX_HEIGHT
    RECMD_SCROLL=true
  fi
  if [ "$RECMD_WIDTH" -gt "$MAX_WIDTH" ]; then
    RECMD_WIDTH=$MAX_WIDTH
    #RECMD_SCROLL=true
  fi

  if [ "$RECMD_HEIGHT" -lt "$MIN_HEIGHT" ] ; then
    RECMD_HEIGHT=$MIN_HEIGHT
    RECMD_SCROLL=false
  fi
  if [ "$RECMD_WIDTH" -lt "$MIN_WIDTH" ]; then
    RECMD_WIDTH=$MIN_WIDTH
    RECMD_SCROLL=false
  fi

  TEST_STRING="" #blank out for memory's sake
}

function relaunchIfNotVisible() {
  parentScript=$(basename "$0")

  if [ "$GUI" == "false" ] && [ "$terminal" == "false" ]; then
    if [ -e "/tmp/relaunching" ] && [ "$(cat /tmp/relaunching)" == "$parentScript" ]; then
      echo "Won't relaunch $parentScript more than once"
    else
      echo "$parentScript" > /tmp/relaunching

      echo "Relaunching $parentScript ..."

      TERMINAL=xterm
      # Launch in whatever terminal is available
      if command -v >/dev/null x-terminal-emulator; then
        TERMINAL=x-terminal-emulator
      elif [ "$desktop" != "gnome" ] && command -v >/dev/null kdialog; then
        TERMINAL=kdialog
      elif [ "$desktop" != "kde" ] && command -v >/dev/null gnome-terminal; then
        TERMINAL=gnome-terminal
      elif command -v >/dev/null xfce4-terminal; then
        TERMINAL=xfce4-terminal
      elif command -v >/dev/null qterminal; then
        TERMINAL=qterminal
      fi
      $TERMINAL -e "./$parentScript"
      rm /tmp/relaunching
      exit $?;
    fi
  fi
}

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

function message-info() {
  local SYMBOL=$INFO_SYMBOL
  messagebox "$@"
}

function message-warn() {
  GUI_ICON=$XDG_ICO_WARN
  local KDIALOG_ARG=--sorry
  local SYMBOL=$WARN_SYMBOL
  echo -n "${yellow}"
  messagebox "$@"
  echo -n "${normal}"
}

function message-error() {
  GUI_ICON=$XDG_ICO_ERROR
  local KDIALOG_ARG=--error
  local SYMBOL=$ERR_SYMBOL
  echo -n "${red}"
  messagebox "$@"
  echo -n "${normal}"
}

function messagebox() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_INFO
  fi
  if [ -z ${KDIALOG_ARG+x} ]; then
    KDIALOG_ARG=--msgbox
  fi
  updateGUITitle
  TEST_STRING="${SYMBOL}$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "${SYMBOL}$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "${SYMBOL}$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --info --text "$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" "$KDIALOG_ARG" "$1"
  else
    echo -e "${SYMBOL}$1"
  fi
}

function yesno() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  updateGUITitle
  TEST_STRING="${QUESTION_SYMBOL}$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "${QUESTION_SYMBOL}$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
    answer=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
    answer=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --question --text "$1"
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

function inputbox() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi

  if [ -z ${SYMBOL+x} ]; then
    local SYMBOL=$QUESTION_SYMBOL
  fi

  updateGUITitle
  TEST_STRING="${QUESTION_SYMBOL} $1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_HEIGHT" "$RECMD_WIDTH" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "${SYMBOL} $1" "$RECMD_HEIGHT" "$RECMD_WIDTH" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT="$(zenity --entry --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --text="$1" --entry-text "$2")"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT="$(kdialog --title "$GUI_TITLE" --icon "$GUI_ICON" --inputbox "$1" "$2")"
  else
    read -ei "$2" -rp "${SYMBOL}${bold}$1: ${normal}" INPUT
  fi

  echo "$INPUT"
}

function userandpassword() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_PASSWORD
  fi
  updateGUITitle
  TEST_STRING="$4"
  calculateTextDialogSize

  local __uservar="$1"
  local __passvar="$2"
  local SUGGESTED_USERNAME="$3"
  local USER_TEXT="$4"
  if [ "$USER_TEXT" == "" ]; then USER_TEXT="Username"; fi
  local PASS_TEXT="$5"
  if [ "$PASS_TEXT" == "" ]; then PASS_TEXT="Password"; fi
  CREDS=()

  if [ "$INTERFACE" == "whiptail" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$PASS_TEXT" "$RECMD_HEIGHT" "$RECMD_WIDTH" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    mapfile -t CREDS < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --insecure --mixedform "Login:" "$RECMD_HEIGHT" "$RECMD_WIDTH" 0 "Username: " 1 1 "$SUGGESTED_USERNAME" 1 11 22 0 0 "Password :" 2 1 "" 2 11 22 0 1 3>&1 1>&2 2>&3 )
  elif [ "$INTERFACE" == "zenity" ]; then
    ENTRY=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --password --username "$SUGGESTED_USERNAME")
    CREDS[0]=$(echo "$ENTRY" | cut -d'|' -f1)
    CREDS[1]=$(echo "$ENTRY" | cut -d'|' -f2)
  elif [ "$INTERFACE" == "kdialog" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$PASS_TEXT")
  else
    read -ei "$SUGGESTED_USERNAME" -rp "${QUESTION_SYMBOL}${bold}$USER_TEXT: ${normal}" "CREDS[0]"
    read -srp "${bold}${PASSWORD_SYMBOL}$PASS_TEXT: ${normal}" "CREDS[1]"
    echo
  fi
  
  eval "$__uservar"="'${CREDS[0]}'"
  eval "$__passvar"="'${CREDS[1]}'"
}

function password() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_PASSWORD
  fi
  updateGUITitle
  TEST_STRING="{PASSWORD_SYMBOL}$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    PASSWORD=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    PASSWORD=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    PASSWORD=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --password)
  elif [ "$INTERFACE" == "kdialog" ]; then
    PASSWORD=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --password "$1")
  else
    read -srp "{PASSWORD_SYMBOL}${bold}$ACTIVITY: ${normal}" PASSWORD
  fi
  echo "$PASSWORD"
}

function displayFile() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_DOCUMENT
  fi
  updateGUITitle
  TEST_STRING="$(cat "$1")"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --textbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --text-info --filename="$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --textbox "$1" 512 256
  else
    less "$1" 3>&1 1>&2 2>&3
  fi
}

function checklist() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  updateGUITitle
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    mapfile -t CHOSEN_ITEMS < <( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --checklist "${QUESTION_SYMBOL}$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    IFS=$'\n' read -r -d '' -a CHOSEN_LIST < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --separate-output --checklist "${QUESTION_SYMBOL}$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)

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
    IFS=$'|' read -r -d '' -a CHOSEN_LIST < <( zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --list --text "$TEXT" --checklist --column "" --column "Value" --column "Description" "${OPTIONS[@]}" )

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

function radiolist() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_QUESTION
  fi
  updateGUITitle
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    CHOSEN_ITEM=$( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "${QUESTION_SYMBOL}$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    CHOSEN_ITEM=$( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --quoted --radiolist "${QUESTION_SYMBOL}$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
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
    CHOSEN_ITEM=$( zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --list --text "$TEXT" --radiolist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")
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

function progressbar() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_INFO
  fi
  updateGUITitle

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --gauge "$ACTIVITY" "$RECMD_HEIGHT" "$RECMD_WIDTH" 0
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "" "$RECMD_HEIGHT" "$RECMD_WIDTH" 0
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --progress --text="$ACTIVITY" --auto-close --auto-kill --percentage 0
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
    echo -ne "\r${HOURGLASS_SYMBOL}$ACTIVITY 0%"
    cat
  fi
}

function progressbar_update() {
  if [ "$INTERFACE" == "kdialog" ]; then
    DBUS_BAR_PATH=/tmp/script-dialog.$$/progressbar_dbus
	if [ -e $DBUS_BAR_PATH ]; then
		read -r -d '' -a dbusRef < <( cat $DBUS_BAR_PATH )
		qdbus "${dbusRef[@]}" Set "" value "$1"
		sleep 0.2 # requires slight sleep
	else
		echo -e "Could not update progressbar $$"
    fi
  elif [ "$INTERFACE" == "whiptail" ] || [ "$INTERFACE" == "dialog" ] || [ "$INTERFACE" == "zenity" ]; then
    echo -e "$1"
  else
    echo -ne "\r${HOURGLASS_SYMBOL}$ACTIVITY $1%"
  fi
}

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
}

function filepicker() {
  if [ -z ${GUI_ICON+x} ]; then
    if [ "$2" == "save" ]; then
      GUI_ICON=$XDG_ICO_SAVE
    else
      GUI_ICON=$XDG_ICO_FILE_OPEN
    fi
  fi
  updateGUITitle
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2012
    read -r -d '' -a files < <(ls -lBhpa "$1" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_HEIGHT)) $((6+RECMD_WIDTH)) $RECMD_HEIGHT "${files[@]}" 3>&1 1>&2 2>&3)
    FILE="$1/$SELECTED"

    #exitstatus=$?
    #if [ $exitstatus != 0 ]; then
        #echo "CANCELLED!"
        #exit;
    #fi

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --fselect "$1"/ 14 48)
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --file-selection --filename "$1"/ )
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

    # TODO if SELECTED is empty or folder

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

function folderpicker() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_FOLDER_OPEN
  fi
  updateGUITitle
  if [ "$INTERFACE" == "whiptail" ]; then
    # shellcheck disable=SC2010
    read -r -d '' -a files < <(ls -lBhpa "$1" | grep "^d" | awk -F ' ' ' { print $9 " " $5 } ')
    SELECTED=$(whiptail --clear --backtitle "$APP_NAME" --title "$GUI_TITLE"  --cancel-button Cancel --ok-button Select --menu "$ACTIVITY" $((8+RECMD_HEIGHT)) $((6+RECMD_WIDTH)) $RECMD_HEIGHT "${files[@]}" 3>&1 1>&2 2>&3)
    FILE="$1/$SELECTED"

    #exitstatus=$?
    #if [ $exitstatus != 0 ]; then
        #echo "CANCELLED!"
        #exit;
    #fi

  elif [ "$INTERFACE" == "dialog" ]; then
    FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --dselect "$1"/ 14 48)
  elif [ "$INTERFACE" == "zenity" ]; then
    FILE=$(zenity --title "$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --file-selection --directory --filename "$1"/ )
  elif [ "$INTERFACE" == "kdialog" ]; then
    FILE=$(kdialog --title="$GUI_TITLE" --icon "$GUI_ICON" --getexistingdirectory "$1"/ )
  else
    read -erp "${FOLDER_SYMBOL}You need to select a folder in $1/. Hit enter to browse this folder"

    # shellcheck disable=SC2010
    ls -lBhpa "$1" | grep "^d" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED

    # TODO if SELECTED is empty or ..

    FILE=$1/$SELECTED
  fi

  echo "$FILE"
}

function datepicker() {
  if [ -z ${GUI_ICON+x} ]; then
    GUI_ICON=$XDG_ICO_CALENDAR
  fi
  updateGUITitle

  NOW=$( printf '%(%d/%m/%Y)T' )
  DAY=$( printf '%(%d)T' )
  MONTH=$( printf '%(%m)T' )
  YEAR=$( printf '%(%Yd)T' )

  if [ "$INTERFACE" == "whiptail" ]; then
    local SYMBOL=$CALENDAR_SYMBOL
    STANDARD_DATE=$(inputbox "Input Date (DD/MM/YYYY)" "$NOW")
  elif [ "$INTERFACE" == "dialog" ]; then
    STANDARD_DATE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --calendar "${CALENDAR_SYMBOL}Choose Date" 0 40)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT_DATE=$(zenity --title="$GUI_TITLE" $ZENITY_ICON_ARG "$GUI_ICON" --calendar "Select Date")
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
    read -ei "$NOW" -rp "${CALENDAR_SYMBOL}${bold}Date (DD/MM/YYYY): ${normal}" STANDARD_DATE
  fi

  echo "$STANDARD_DATE"
}
