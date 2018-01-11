#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo "Run this script as root" 1>&2
   exit 1
fi

cp .pgpass ~/ #fichero conexion a base datos postgres
mkdir /tmp/backups/ #ficheros temporales de backup
mkdir /var/log/backups/
cp -r etc/* /etc/
cp -r bin/* /usr/local/bin/
cp systemd/backup* /etc/systemd/system/ #timers/services
#ln -s ~/systemd/backup* /etc/systemd/system/
systemctl daemon-reload
