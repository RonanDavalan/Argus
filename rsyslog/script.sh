#!/bin/bash

YESTERDAY=""

help() {
	cat << TRUC >&2
...
TRUC
}

usage() {
	cat << EOF >&2
...
EOF
}

args() {
    local opt
    while getopts "hy" opt; do
        case $opt in
            h) help; exit 0;;
            y) YESTERDAY=$(date -d yesterday "+%Y-%m-%d");;
            ?) usage;;
        esac
    done
    shift $(($OPTIND - 1))
    [ $# -gt 1 ] && usage
}

filter() {
	local day
	if [ "$1" != "" ]; then
		LINES=$(cat $LOGS | grep "^$1")
	elif [ "$YESTERDAY" != "" ]; then
		LINES=$(cat $LOGS | grep "^$YESTERDAY")
	fi

	day=$(echo "$LINES" | grep NOTICE | tr -s ' ' | cut -d ' ' -f 6 | sort | uniq -c)

	echo "$day" | while read d; do echo "$d $1"; done

}
	

#set -x 
LOGS="/tmp/log.txt"

# Format de sortie :
# service nombre_ip_bannies

# Main

args $@

if [ "$YESTERDAY" != "" ]; then
	DAYS=$YESTERDAY
else
	DAYS=$(cat $LOGS | grep NOTICE | cut -d ' ' -f 1 | sort -u)
fi

for i in $DAYS; do 
	filter $i 
done

