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

cp templates/server.conf "/etc/nginx/sites-available/$WEB"

sed -i "s/my_host/$WEB/g" "/etc/nginx/sites-available/$WEB"

if [ ! -f /etc/nginx/sites-available/https.conf ]; then
    ln -s $(realpath templates/https.conf) /etc/nginx/sites-available/https.conf
fi

mkdir -p "/home/pi/www/$WEB"

if [ ! -f "/home/pi/www/$WEB/index.html" ]; then
    cp templates/index.html "/home/pi/www/$WEB/index.html"
fi

if [ ! -f "/etc/nginx/sites-enabled/$WEB" ]; then
    ln -s "/etc/nginx/sites-available/$WEB" "/etc/nginx/sites-enabled/$WEB"
fi
