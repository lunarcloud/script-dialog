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

# which sudo to use
if [ "`which kdesudo`" > /dev/null ] && [ "$INTERFACE" == "kdialog" ]; then
    SUDO="kdesudo"
elif [ `which gksudo` > /dev/null ] && [ "$INTERFACE" == "zenity" ]; then
    SUDO="gksudo"
elif [ `which gksu` > /dev/null ] && [ "$INTERFACE" == "zenity" ]; then
    SUDO="gksu"
elif [ `which sudo` > /dev/null ]; then
    SUDO="sudo"
fi

APP_NAME="Script"
ACTIVITYEAR=""
GUI_TITLE="$APP_NAME"

function superuser() {
    ARGS=""
    while (( $# )); do
        ARGS="$ARGS $1"
        shift
    done
	$SUDO $ARGS
}

function updateGUITitle() {
    if [ -n "$ACTIVITY" ]; then
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
		whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" 20 80
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --msgbox "$1" 20 80
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
		whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" 20 80
		answer=$?
	elif [ "$INTERFACE" == "dialog" ]; then
		dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --yesno "$1" 20 80
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

function inputbox() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
        INPUT=$(whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" 10 40  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "dialog" ]; then
        INPUT=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --inputbox " $1" 10 40  3>&1 1>&2 2>&3)
	elif [ "$INTERFACE" == "zenity" ]; then
		INPUT="`zenity --entry --title="$GUI_TITLE" --text="$1" --entry-text "$2"`"
	elif [ "$INTERFACE" == "kdialog" ]; then
		INPUT="`kdialog --title "$GUI_TITLE" --inputbox "$1" "$2"`"
		echo "$INPUT" > log.txt
	else
		read -p "$1: " INPUT
	fi

	echo "$INPUT"
}

function userandpassword() {
    updateGUITitle
	if [ "$INTERFACE" == "whiptail" ]; then
        inputbox "$1"
        whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$2" 10 40
	elif [ "$INTERFACE" == "dialog" ]; then
        inputbox "$1"
		dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --passwordbox "$2" 10 40
	elif [ "$INTERFACE" == "zenity" ]; then
        ENTRYEAR=`zenity --title="$GUI_TITLE" --password --username`
        USERNAME=`echo $ENTRY | cut -d'|' -f1`
        PASSWORDAY=`echo $ENTRY | cut -d'|' -f2`
	elif [ "$INTERFACE" == "kdialog" ]; then
        inputbox "$1"
		password=`kdialog --title="$GUI_TITLE" --password "$2"`
	else
		read -p "username: " USERNAME
        read  -sp "password: " PASSWORD
	fi
}

function displayFile() {
    updateGUITitle
    if [ "$INTERFACE" == "whiptail" ]; then
        whiptail --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --scrolltext --textbox "$1" 12 80
    elif [ "$INTERFACE" == "dialog" ]; then
        dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --scrolltext --textbox "$1" 12 80
    elif [ "$INTERFACE" == "zenity" ]; then
        zenity --title="$GUI_TITLE" --text-info --filename="$1"
    elif [ "$INTERFACE" == "kdialog" ]; then
        kdialog --title="$GUI_TITLE" --textbox "$1" 512 256
    else
        more $FILE
    fi
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
		echo "$ACTIVITY:"
		while test ${#} -gt 0
        do
            yesno $2
            shift
            shift
            shift
        done
	fi
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
        OPTION_COUNT=${#[@]}
        ITERATOR=0
        CHOICE=0
		if [ $CHOICE -le 0 ] || [ $CHOICE -gt $OPTION_COUNT ] ; then
            echo "$ACTIVITY: "
            while test ${#} -gt 0; do
                ((ITERATOR++))
                echo "$ITERATOR $2"
                shift
                shift
                shift
            done
            read CHOICE
        fi
    fi
}

function progressbar() {
    updateGUITitle
    if [ "$INTERFACE" == "whiptail" ]; then
        messagebox "not implemented" #TODO
    elif [ "$INTERFACE" == "dialog" ]; then
        echo percentage | dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "$1" 10 70 0
        sleep 1
        echo "10" | dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "$1" 10 70 0
        sleep 1
        echo "50" | dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "$1" 10 70 0
        sleep 1
        echo "100" | dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY"  --gauge "$1" 10 70 0
    elif [ "$INTERFACE" == "zenity" ]; then
        messagebox "not implemented" #TODO
    elif [ "$INTERFACE" == "kdialog" ]; then
        messagebox "not implemented" #TODO
    else
        messagebox "not implemented" #TODO
    fi
}

function filepicker() {
    updateGUITitle
    if [ "$INTERFACE" == "whiptail" ]; then
        messagebox "not implemented" #TODO
    elif [ "$INTERFACE" == "dialog" ]; then
        #needs work to support driving down into files
        FILE=$(dialog --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --stdout --fselect $HOME/ 14 48)
    elif [ "$INTERFACE" == "zenity" ]; then
        messagebox "not implemented" #TODO
    elif [ "$INTERFACE" == "kdialog" ]; then
        messagebox "not implemented" #TODO
    else
        read -e -p "$1: " FILE
    fi
}

function datepicker() {
    updateGUITitle
    DAY="0"
    MONTH="0"
    YEAR="0"

    if [ "$INTERFACE" == "whiptail" ]; then
        INPUT_DATE=$(inputbox "Input Date (DD/MM/YYYY)" " ")
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "dialog" ]; then
        INPUT_DATE=$(dialog --stdout --clear --backtitle "$APP_NAME" --title "$ACTIVITY" --calendar "Choose Date" 0 40)
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "zenity" ]; then
        INPUT_DATE=$(zenity --calendar "Select Date")
        MONTH=`echo $INPUT_DATE | cut -d'/' -f1`
        DAY=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    elif [ "$INTERFACE" == "kdialog" ]; then
        INPUT_DATE=$(kdialog --calendar "Select Date")
        TEXT_MONTH=`echo $INPUT | cut -d' ' -f2`
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

        DAY=`echo $INPUT | cut -d' ' -f3`
        YEAR=`echo $INPUT | cut -d' ' -f4`
    else
        read -p "Date (DD/MM/YYYY): " INPUT_DATE
        DAY=`echo $INPUT_DATE | cut -d'/' -f1`
        MONTH=`echo $INPUT_DATE | cut -d'/' -f2`
        YEAR=`echo $INPUT_DATE | cut -d'/' -f3`
    fi

    echo "$DAY/$MONTH/$YEAR"
}

