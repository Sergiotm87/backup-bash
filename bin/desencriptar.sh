#!/bin/bash
#
#script para desencriptar los ficheros de una copia de seguridad
#
#ejecucion: desencriptar.sh rutaFicherosEncriptados host

###	variables
ruta=$1
host=$2
#host=$(hostname)
hostBackupDirs=/home/sergio/github/backup-bash/etc/backups/hosts/${host}
configfiles=/home/sergio/github/backup-bash/etc/backups/
#destino=/opt/backup/encrypted/

# function desencriptar(){
#   openssl rsautl -decrypt -inkey ${configfiles}backup.pem -in ${destino}key.encrypted -out ${destino}key.txt
#   openssl enc -aes-256-cbc -d -pass file:${destino}key.txt -in $objeto -out $(echo $objeto | cut -d'.' -f 1,2,3)
#   rm ${destino}key.txt
# }

function desencriptar(){
  openssl rsautl -decrypt -inkey ${configfiles}backup.pem -in ${ruta}key.encrypted -out ${ruta}key.txt
  while read line; do
    option=$(echo ${line} | cut -d' ' -f1)
    fichero=$(echo ${line} | cut -d' ' -f2)
    if [[ ${option} == 'C' ]]; then
      openssl enc -aes-256-cbc -d -pass file:${ruta}key.txt -in ${fichero} -out $(echo $fichero | cut -d'.' -f 1,2,3)
      tar -xzf ${fichero}.tar.gz
    fi
  done <${hostBackupDirs}
  rm ${ruta}key.txt
}

desencriptar
