#!/bin/sh

#variables
MODE=$1
SDL_BACKUP=${TMPDIR-/tmp}"/sdL_backup"
SDL_TMP=${TMPDIR-/tmp}"/fs/mp/images/ivsu_cache"
SDL=${2%/}

#functions
usage() {
    echo "Usage: env.sh [OPTION] [PATH]"
    echo "Path is a link to SDL bin folder"
    echo "Mode can be the following:"
    echo "  -b, --backup - Back up SDL configuration"
    echo "  -c, --clean - Remove temporary SDL working files"
    echo "  -r, --restore - Restore SDL configuration from backup"
    echo "  -h, --help - Display this help"
}

backup() {
	echo "Backup environment"
	rm -r -f $SDL_BACKUP
	mkdir $SDL_BACKUP
	if [ -d $SDL_BACKUP ]; then
		cp $SDL"/hmi_capabilities.json" $SDL_BACKUP
		cp $SDL"/sdl_preloaded_pt.json" $SDL_BACKUP
		cp $SDL"/smartDeviceLink.ini" $SDL_BACKUP
		echo "Done"
	else
		echo "Unable to create '"$SDL_BACKUP"' folder"
	fi
}

clean() {
	echo "Clean environment"
	if [ -d $SDL ]; then
		rm -r -f $SDL"/storage"
		rm -f $SDL"/app_info.dat"
		rm -f $SDL"/ProtocolFordHandling.log"
		rm -f $SDL"/SmartDeviceLinkCore.log"
		rm -f $SDL"/TransportManager.log"
		rm -r -f $SDL_TMP
		echo "Done"
	fi
}

restore() {
	echo "Restore environment"
	if [ -d $SDL_BACKUP ]; then
		cp $SDL_BACKUP"/hmi_capabilities.json" $SDL
		cp $SDL_BACKUP"/sdl_preloaded_pt.json" $SDL
		cp $SDL_BACKUP"/smartDeviceLink.ini" $SDL
		# rm -r -f $SDL_BACKUP
		echo "Done"
	else
		echo "Unable to find '"$SDL_BACKUP"' folder"
	fi
}

#main
if [ ! -d $SDL ]; then
	echo "Unable to find '"$SDL"' folder"
	exit
fi
case $MODE in
	-h | --help)
		usage
		exit
		;;
	-b | --backup)
		backup
		exit
		;;
	-c | --clean)
		clean
		exit
		;;
	-r | --restore)
		restore
		exit
		;;
esac

