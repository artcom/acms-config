#!/usr/bin/env sh
/usr/sbin/fcgiwrap -s unix:/var/run/fcgiwrap.socket &

# Wait until the socket is available before nginx starts
while [ ! -S /var/run/fcgiwrap.socket ]; do
    sleep 0.1
done
chown www-data:www-data /var/run/fcgiwrap.socket
