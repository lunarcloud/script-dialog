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

if [ "$desktop" == "kde" ]; then
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
elif [ "$INTERFACE" == "" ]; then
	if  [ $hasWhiptail == true ] ; then
		INTERFACE="whiptail"
		GUI=false
	elif  [ $hasDialog == true ] ; then
		INTERFACE="dialog"
		GUI=false
	fi
else
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
fi

TITLE="Script"

function relaunchIfNotVisible() {
	parentScript=$(basename `readlink -f ${BASH_SOURCE[0]}`)

	if [ $GUI == false ] && [ $terminal == false ]; then
		x-terminal-emulator --hold -e "./$parentScript"
		exit $?;
	fi
}

function messagebox() {
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --backtitle "$TITLE" --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --backtitle "$TITLE" --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$TITLE" --info --text "$1"
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$TITLE" --msgbox "$1"
	else
		echo "$1"
	fi
}

function yesno() {
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --backtitle "$TITLE" --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --backtitle "$TITLE" --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --title "$TITLE" --question --text "$1"
		answer=$?
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --title "$TITLE" --yesno "$1"
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
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi
}

function inputBox() {
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi

	return "TODO"
}

function passwordBox() {
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi

	return "TODO"
}

function checklist() {
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi

	return "TODO"
}

function radioList() {
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi

	return "TODO"
}

function progressBar() {
	if [ "$INTERFACE" == "whiptail" ]; then
		#TODO
	elif [ "$INTERFACE" == "dialog" ]; then
		#TODO
	elif [ "$INTERFACE" == "zenity" ]; then
		#TODO
	elif [ "$INTERFACE" == "kdialog" ]; then
		#TODO
	else
		#TODO
	fi
}
