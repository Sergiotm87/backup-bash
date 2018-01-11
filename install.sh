#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo "Run this script as root" 1>&2
   exit 1
fi

mkdir /tmp/backups/
mkdir /var/log/backups/logs
cp -r etc/* /etc/
cp -r bin/* /usr/local/bin/
cp systemd/backup* /etc/systemd/system/
#ln -s ~/systemd/backup* /etc/systemd/system/
systemctl daemon-reload
