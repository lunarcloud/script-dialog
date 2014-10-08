#!/bin/bash
#multi-ui scripting

if [ "$XDG_CURRENT_DESKTOP" = "" ]
then
  desktop=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
else
  desktop=$XDG_CURRENT_DESKTOP
fi

desktop=${desktop,,}  # convert to lower case

[ -t 0 ] && terminal=1

if xdpyinfo | grep X.Org > /dev/null; then
	if [ $terminal ] ; then
		GUI=false
	else
		GUI=true
	fi
else
	GUI=false
fi

if which kdialog > /dev/null; then
	hasKDialog=true
else
	hasKDialog=false
fi

if which zenity > /dev/null; then
	hasZenity=true
else
	hasZenity=false
fi

if which whiptail > /dev/null; then
	hasWhiptail=true
else
	hasWhiptail=false
fi

if which dialog > /dev/null; then
	hasDialog=true
else
	hasDialog=false
fi

if [ "$desktop" == "kde" ] || [ "$desktop" == "razor" ]  || [ "$desktop" == "lxqt" ]  || [ "$desktop" == "maui" ] ; then
	if  [ $hasKDialog == true ] && [ $GUI == true ] ; then
		INTERFACE="kdialog"
		GUI=true
	elif [ $hasZenity == true ] && [ $GUI == true ] ; then
		INTERFACE="zenity"
		GUI=true
	elif  [ $hasWhiptail == true ] ; then
		INTERFACE="whiptail"
		GUI=false
	elif  [ $hasDialog == true ] ; then
		INTERFACE="dialog"
		GUI=false
	fi
elif [ "$desktop" == "unity" ] || [ "$desktop" == "gnome" ]  || [ "$desktop" == "xfce" ]  || [ -n $INTERFACE ]; then
    if [ $hasZenity == true ] && [ $GUI == true ] ; then
        INTERFACE="zenity"
        GUI=true
    elif  [ $hasWhiptail == true ] ; then
        INTERFACE="whiptail"
        GUI=false
    elif  [ $hasDialog == true ] ; then
        INTERFACE="dialog"
        GUI=false
    fi
else
    if  [ $hasWhiptail == true ] ; then
        INTERFACE="whiptail"
        GUI=false
    elif  [ $hasDialog == true ] ; then
        INTERFACE="dialog"
        GUI=false
    fi
fi

APP_NAME="Script"
ACTIVITY=""
GUI_TITLE="$APP_NAME"

function updateGUITitle() {
    if [ -n $ACTIVITY ]; then
        GUI_TITLE="$ACTIVITY - $APP_NAME"
    else
        GUI_TITLE="$APP_NAME"
    fi
}

function relaunchIfNotVisible() {
	parentScript=$(basename `readlink -f ${BASH_SOURCE[0]}`)

	if [ $GUI == false ] && [ $terminal == false ]; then
		x-terminal-emulator --hold -e "./$parentScript"
		exit $?;
	fi
}

function messagebox() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$GUI_TITLE" --info --text "$1"
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$GUI_TITLE" --msgbox "$1"
	else
		echo "$1"
	fi
}

function yesno() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$GUI_TITLE" --question --text "$1"
		answer=$?
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$GUI_TITLE" --yesno "$1"
		answer=$?
	else
		echo "$1 (y/n)"
		read answer
		if [ "$answer" == "y" ]; then
			answer=0
		else
			answer=1
		fi
	fi

	return $answer
}

function displayFile() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		echo "not implemented" #TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		echo "not implemented" #TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		echo "not implemented" #TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		echo "not implemented" #TODO
	else
		echo "not implemented" #TODO
	fi
}

function echoerr() {
    echo "$@" 1>&2;
}

function inputbox() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
        TMP=$(mktemp)
        whiptail --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "$1" 10 40 2>$TMP
        INPUT=$(cat "$TMP")
        rm "$TMP"
	elif [ "$INTERFACE" == "dialog" ]; then
        TMP=$(mktemp)
        dialog --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox "$1" 10 40 2>$TMP
        INPUT=$(cat "$TMP")
        rm "$TMP"
	elif [ "$INTERFACE" == "zenity" ]; then
		INPUT="`zenity --entry --title="$GUI_TITLE" --text="$1" --entry-text "$2"`"
	elif [ "$INTERFACE" == "kdialog" ]; then
		INPUT="`kdialog --title "$GUI_TITLE" --inputbox "$1" "$2"`"
	else
		read -p "$1: " INPUT
	fi

	echoerr "$INPUT"
}

function passwordbox() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		messagebox "not implemented" #TODO
	else
		messagebox "not implemented" #TODO
	fi

	return "TODO"
}

function checklist() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		messagebox "not implemented" #TODO
	else
		messagebox "not implemented" #TODO
	fi

	return "TODO"
}

function radiolist() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		messagebox "not implemented" #TODO
	else
		messagebox "not implemented" #TODO
	fi

	return "TODO"
}

function progressbar() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		messagebox "not implemented" #TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		messagebox "not implemented" #TODO
	else
		messagebox "not implemented" #TODO
	fi
}
