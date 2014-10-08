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

if [ "$desktop" == "kde" ]; then
	if  [ $hasKDialog == true ] && [ $GUI == true ] ; then
		INTERFACE="kdialog"
	else
		INTERFACE="whiptail"
	fi
elif [ "$INTERFACE" == "" ]; then
	INTERFACE="whiptail"
else
	if [ $hasZenity == true ] && [ $GUI == true ] ; then
		INTERFACE="zenity"
	else
		INTERFACE="whiptail"
	fi
fi

function messagebox() {
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --info --text "$1"
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --msgbox "$1"
	else
		echo "$1"
	fi
}

function yesno() {
	if [ "$INTERFACE" == "whiptail" ]; then
		whiptail --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "zenity" ]; then
		zenity --question --text "$1"
		answer=$?
	elif [ "$INTERFACE" == "kdialog" ]; then
		kdialog --yesno "$1"
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
