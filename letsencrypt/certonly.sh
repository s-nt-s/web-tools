#!/bin/bash
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit
fi

if [ $# -ne 1 ]; then
    echo "You must to give a server_narme as a argument"
fi

cd "$(dirname "$0")"

WEB="$1"

./certbot-auto certonly --nginx -d "$WEB,www.$WEB"
