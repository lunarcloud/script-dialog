#!/bin/bash
#multi-ui scripting

# Disable this rule, as it interferes with purely-numeric parameters
# shellcheck disable=SC2046

if [[ $OSTYPE == darwin* ]]; then
    desktop="macos"
elif [[ $OSTYPE == msys ]] || [[ $(uname -r | tr '[:upper:]' '[:lower:]') == *wsl* ]]; then
    desktop="windows"
elif [ -n "$XDG_SESSION_DESKTOP" ]; then
  # shellcheck disable=SC2001
  desktop=$(echo "$XDG_SESSION_DESKTOP" | tr '[:upper:]' '[:lower:]' | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
elif [ -n "$XDG_CURRENT_DESKTOP" ]; then
  # shellcheck disable=SC2001
  desktop=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]' | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
elif [ -n "$XDG_DATA_DIRS" ]; then
  # shellcheck disable=SC2001
  desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
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

if [ "$GUI" == "true" ] ; then
  if command -v >/dev/null kdialog; then
    hasKDialog=true
  fi

  if command -v >/dev/null zenity; then
    hasZenity=true
  fi
else
  if command -v >/dev/null dialog; then
    hasDialog=true
  fi

  if command -v >/dev/null whiptail; then
    hasWhiptail=true
  fi
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
WINDOW_ICON=""
GUI_TITLE="$APP_NAME"

function superuser() {
  if [ $NO_SUDO == true ]; then
    (>&2 echo "No sudo available!")
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
function standardIconInfo() {
  echo "dialog-information"
}
function standardIconQuestion() {
  echo "dialog-question"
}
function standardIconError() {
  echo "dialog-error"
}
function standardIconWarning() {
  echo "dialog-warning"
}
function standardIconFolderOpen() {
  echo "folder-open"
}
function standardIconFolderSave() {
  if [ "$INTERFACE" == "zenity" ]; then
    echo "document-save"
  elif [ "$INTERFACE" == "kdialog" ]; then
    echo "folder-save"
  else
    echo ""
  fi
}
function standardIconFileOpen() {
  echo "document-open"
}
function standardIconFileSave() {
  echo "document-save"
}
function standardIconPassword() {
  echo "dialog-password"
}

function standardIconCalendar() {
  echo "x-office-calendar"
}
function standardIconDocument() {
  echo "x-office-document"
}
#end standard icons

function messagebox() {
  updateGUITitle
  TEST_STRING="$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --info --text "$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --msgbox "$1"
  else
    echo -e "$1"
  fi
}

function yesno() {
  updateGUITitle
  TEST_STRING="$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
    answer=$?
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
    answer=$?
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --question --text "$1"
    answer=$?
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --yesno "$1"
    answer=$?
  else
    echo "$1 (y/n)" 3>&1 1>&2 2>&3
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
  updateGUITitle
  TEST_STRING="$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" "$RECMD_HEIGHT" "$RECMD_WIDTH" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" "$RECMD_HEIGHT" "$RECMD_WIDTH" "$2" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT="$(zenity --entry --title="$GUI_TITLE" --icon "$WINDOW_ICON" --text="$1" --entry-text "$2")"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT="$(kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --inputbox "$1" "$2")"
  else
    read -rp "$1: " INPUT
  fi

  echo "$INPUT"
}

function userandpassword() {
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
    ENTRY=$(zenity --title="$GUI_TITLE" --icon "$WINDOW_ICON" --password --username)
    CREDS[0]=$(echo "$ENTRY" | cut -d'|' -f1)
    CREDS[1]=$(echo "$ENTRY" | cut -d'|' -f2)
  elif [ "$INTERFACE" == "kdialog" ]; then
    CREDS[0]=$(inputbox "$USER_TEXT" "$SUGGESTED_USERNAME")
    CREDS[1]=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --password "$PASS_TEXT")
  else
    read -rp "$USER_TEXT ($SUGGESTED_USERNAME): " "CREDS[0]"
    read -srp "$PASS_TEXT: " "CREDS[1]"
  fi
  
  eval "$__uservar"="'${CREDS[0]}'"
  eval "$__passvar"="'${CREDS[1]}'"
}

function password() {
  updateGUITitle
  TEST_STRING="$1"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    PASSWORD=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    PASSWORD=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH" 3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "zenity" ]; then
    PASSWORD=$(zenity --title="$GUI_TITLE" --icon "$WINDOW_ICON" --password)
  elif [ "$INTERFACE" == "kdialog" ]; then
    PASSWORD=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --password "$1")
  else
    read -srp "$ACTIVITY: " PASSWORD
  fi
  echo "$PASSWORD"
}

function displayFile() {
  updateGUITitle
  TEST_STRING="$(cat "$1")"
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")  --textbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --textbox "$1" "$RECMD_HEIGHT" "$RECMD_WIDTH"
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title="$GUI_TITLE" --icon "$WINDOW_ICON" --text-info --filename="$1"
  elif [ "$INTERFACE" == "kdialog" ]; then
    kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --textbox "$1" 512 256
  else
    less "$1" 3>&1 1>&2 2>&3
  fi
}

function checklist() {
  updateGUITitle
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    mapfile -t CHOSEN < <( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --checklist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    IFS=$'\n' read -r -d '' -a CHOSEN_LIST < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --separate-output --checklist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)

    CHOSEN=()
    for value in "${CHOSEN_LIST[@]}"
    do
      CHOSEN+=( "\"$value\"" )
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
    IFS=$'|' read -r -d '' -a CHOSEN_LIST < <( zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --list --text "$TEXT" --checklist --column "" --column "Value" --column "Description" "${OPTIONS[@]}" )

    CHOSEN=()
    for value in "${CHOSEN_LIST[@]}"
    do
      CHOSEN+=( "\"$value\"" )
    done

  elif [ "$INTERFACE" == "kdialog" ]; then
    mapfile -t CHOSEN < <( kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --checklist "$TEXT" "$@")
  else
    printf "%s\n $TEXT:\n" "$ACTIVITY" 3>&1 1>&2 2>&3
    CHOSEN=()
    while test ${#} -gt 0; do
      if yesno "$2 (default: $3)?"; then
        CHOSEN+=( "\"$1\"" )
      fi
      shift
      shift
      shift
    done
  fi

  echo "${CHOSEN[@]}"
}

function radiolist() {
  updateGUITitle
  TEXT=$1
  NUM_OPTIONS=$2
  shift
  shift
  calculateTextDialogSize

  if [ "$INTERFACE" == "whiptail" ]; then
    mapfile -t CHOSEN < <( whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --radiolist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
  elif [ "$INTERFACE" == "dialog" ]; then
    IFS=$'\n' mapfile -t CHOSEN < <( dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" $([ "$RECMD_SCROLL" == true ] && echo "--scrolltext") --quoted --radiolist "$TEXT" $RECMD_HEIGHT $MAX_WIDTH "$NUM_OPTIONS" "$@"  3>&1 1>&2 2>&3)
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
    IFS=$'|' mapfile -t CHOSEN < <( zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --list --text "$TEXT" --radiolist --column "" --column "Value" --column "Description" "${OPTIONS[@]}")
  elif [ "$INTERFACE" == "kdialog" ]; then
    mapfile -t CHOSEN < <( kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --radiolist "$TEXT" "$@")
  else
    echo "$ACTIVITY: " 3>&1 1>&2 2>&3
    OPTIONS=()
    while test ${#} -gt 0;  do
      OPTIONS+=("\t$1 ($2)\n")
      shift
      shift
      shift
    done
    read -rp "$(echo -e "${OPTIONS[*]}$TEXT: ")" CHOSEN
  fi

  echo "$CHOSEN"
}

function progressbar() {
  updateGUITitle

  if [ "$INTERFACE" == "whiptail" ]; then
    whiptail --gauge "$ACTIVITY" "$RECMD_HEIGHT" "$RECMD_WIDTH" 0
  elif [ "$INTERFACE" == "dialog" ]; then
    dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "" "$RECMD_HEIGHT" "$RECMD_WIDTH" 0
  elif [ "$INTERFACE" == "zenity" ]; then
    zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --progress --text="$ACTIVITY" --auto-close --auto-kill --percentage 0
  elif [ "$INTERFACE" == "kdialog" ]; then
    read -r -d '' -a dbusRef < <( kdialog --title "$GUI_TITLE" --icon "$WINDOW_ICON" --progressbar "$ACTIVITY" 100)
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
    echo -ne "\r$ACTIVITY 0%"
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
		echo "Could not update progressbar $$"
    fi
  elif [ "$INTERFACE" == "whiptail" ] || [ "$INTERFACE" == "dialog" ] || [ "$INTERFACE" == "zenity" ]; then
    echo "$1"
  else
    #         echo -ne "\r$ACTIVITY $1%"
    echo -ne "\r$ACTIVITY $1%"
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
    FILE=$(zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --file-selection --filename "$1"/ )
  elif [ "$INTERFACE" == "kdialog" ]; then
    if [ "$2" == "save" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --getsavefilename "$1"/ )
    else #elif [ "$2" == "open" ]; then
      FILE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --getopenfilename "$1"/ )
    fi
  else
    read -erp "You need to $2 a file in $1/. Hit enter to browse this folder"

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
    FILE=$(zenity --title "$GUI_TITLE" --icon "$WINDOW_ICON" --file-selection --directory --filename "$1"/ )
  elif [ "$INTERFACE" == "kdialog" ]; then
    FILE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --getexistingdirectory "$1"/ )
  else
    read -erp "You need to select a folder in $1/. Hit enter to browse this folder" 

    # shellcheck disable=SC2010
    ls -lBhpa "$1" | grep "^d" 3>&1 1>&2 2>&3 #| less

    read -erp "Enter name of file to $2 in $1/: " SELECTED

    # TODO if SELECTED is empty or ..

    FILE=$1/$SELECTED
  fi

  echo "$FILE"
}

function datepicker() {
  updateGUITitle
  DAY="0"
  MONTH="0"
  YEAR="0"

  if [ "$INTERFACE" == "whiptail" ]; then
    STANDARD_DATE=$(inputbox "Input Date (DD/MM/YYYY)" " ")
  elif [ "$INTERFACE" == "dialog" ]; then
    STANDARD_DATE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --calendar "Choose Date" 0 40)
  elif [ "$INTERFACE" == "zenity" ]; then
    INPUT_DATE=$(zenity --title="$GUI_TITLE" --icon "$WINDOW_ICON" --calendar "Select Date")
    MONTH=$(echo "$INPUT_DATE" | cut -d'/' -f1)
    DAY=$(echo "$INPUT_DATE" | cut -d'/' -f2)
    YEAR=$(echo "$INPUT_DATE" | cut -d'/' -f3)
    STANDARD_DATE="$DAY/$MONTH/$YEAR"
  elif [ "$INTERFACE" == "kdialog" ]; then
    INPUT_DATE=$(kdialog --title="$GUI_TITLE" --icon "$WINDOW_ICON" --calendar "Select Date")
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
    read -rp "Date (DD/MM/YYYY): " STANDARD_DATE
  fi

  echo "$STANDARD_DATE"
}
