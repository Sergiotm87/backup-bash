#!/usr/bin/env bash
# script de instalacion del sistema de copias de seguridad y sus requisitos

requisitos="rsync postgresql"

if [ "$(id -u)" != "0" ]; then
   echo "ERROR: Ejecutar como root"
   exit 1
fi

echo "comprobando requisitos:"
for pkg in $requisitos; do
    if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$"; then
        echo -e "- $pkg instalado"
    else
        apt-get -qq install $pkg
        echo "- Se ha instalado $pkg"
    fi
done

echo "Añadiendo los componentes del sistema de copias de seguridad"
cp .pgpass ~/ && \
chmod 600 ~/.pgpass && \
mkdir /tmp/backups/ && \
mkdir /var/log/backups/ && \
cp -r etc/* /etc/ && \
cp -r bin/* /usr/local/bin/ && \
cp systemd/backup* /etc/systemd/system/ && \
#ln -s ~/systemd/backup* /etc/systemd/system/
systemctl daemon-reload

if [[ $? = 0 ]]; then
    echo "Sistema instalado, comprobar fichero del host y unidades de systemD:"
    echo "- /etc/backups/hosts/$(hostname)"
    echo "- /etc/systemd/system/backup.."
else
    echo "Error en la instalacion, comprobar manualmente"
fi
