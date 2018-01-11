#!/bin/bash
#
#script para realizar backups completos,incrementales y diferenciales
#ejecucion: backup-bash.sh full|incremental|diferencial [remote]
#requisitos: rsync, postgresql
#

###	variables
host=$(hostname)
BackupLoc=/tmp/backups
BackupType=$1
date=$(date +%Y-%m-%d)
nombreBackup=${host}-${BackupType}-${date}
logFile=/var/log/backups/${nombreBackup}.log
snapshot=${host}.snar
configFiles=/etc/backups/ #par de claves para encriptacion
hostBackupDirs=${configFiles}hosts/${host} #ficheros de cada host con directorios a guardar

remoteDir=/home/debian/backups
remoteHost=172.22.200.42
remoteUser=debian
email=sergiotm87@gmail.com

mickey=172.22.200.45
minnie=172.22.200.81
donald=172.22.200.85

cryptloc=${BackupLoc}/${nombreBackup} #directorio donde se guardan los objetos encriptados

###	comprobaciones

# numero argumentos correctos
if [[ $# != 1 && $# != 2 ]]; then
    echo "ERROR: Argumentos invalidos" | tee -a ${logFile}
    echo "Uso: $0 full|incremental|diferencial [remote]" | tee -a ${logFile}
    exit
fi
# existe directorio temporal de backups
if [ ! -d ${BackupLoc} ]; then
        echo "Creando directorio temporal para backups: ${BackupLoc}"
        mkdir /mnt/backups/
fi
# existe directorio de logs
if [ ! -d ${BackupLoc} ]; then
        echo "Creando directorio de logs: ${BackupLoc}"
        mkdir /var/log/backups/
fi
# tipo de backup correcto
if [[ "${BackupType}" != "full" && "${BackupType}" != "incremental" && "${BackupType}" != "diferencial" ]]; then
        echo "ERROR: Argumentos invalidos" | tee -a ${logFile}
        echo "Ejecutar como <full>, <incremental> o <diferencial>" | tee -a ${logFile}
        exit 1
fi
# existe el fichero del host con los directorios a los que realizar backup
if [ ! -f ${hostBackupDirs} ]; then
        echo "ERROR: no existe el fichero ${hostBackupDirs}" | tee -a ${logFile}
        echo "Especificar a que directorios realizar backup" | tee -a ${logFile}
        exit 1
fi

function makeBackup(){
  echo "Ejecutando Backup" | tee -a ${logFile}
  mkdir ${BackupLoc}/${nombreBackup}
  encriptar
  tar --listed-incremental=${BackupLoc}/${snapshot} -cpzf ${BackupLoc}/${nombreBackup}/${backupFile} $(awk '{if ($1 =="NC") print $2 }' ${hostBackupDirs} | paste -sd " " -) 2>> ${logFile} 1>> ${logFile}
  if [[ $? = 0 ]]; then
          echo "Backup realizado: ${backupFile}" | tee -a ${logFile}
          date > ${BackupLoc}/lastbackup.txt | tee -a ${logFile}
  else
          echo "Backup no realizado" | tee -a ${logFile}
          mail -s "error de backup" ${email} < ${logFile}
          exit 1
  fi
}

function insercionCoconut(){
  echo "Insercion en Coconut.." | tee -a ${logFile}
  status=200
  psql -h 172.22.200.110 -U Sergio.Teran -d db_backup -c "INSERT INTO BACKUPS (backup_user, backup_host, backup_label, backup_description, backup_status, backup_mode) values ('Sergio.Teran', '${!host}','${backupFile}','Copia ${BackupType} de ${host}', '$status', 'Automatica')" 2>> ${logFile} 1>> ${logFile}
  if [[ $? = 0 ]]; then
          echo "Insercion realizada: ${backupFile}" | tee -a ${logFile}
  else
          echo "Insercion no realizado" | tee -a ${logFile}
          mail -s "error de insercion en Coconut" ${email} < ${logFile}
          exit 1
  fi
}

function encriptar(){
  echo "Encriptando ficheros marcados" | tee -a ${logFile}
  openssl rand -out ${cryptloc}/key.txt -base64 48
  while read line; do
    option=$(echo ${line} | cut -d' ' -f1)
    fichero=$(echo ${line} | cut -d' ' -f2)
    ficherotar=${fichero}.tar.gz
    if [[ ${option} == 'C' ]]; then
      tar -cpzf ${ficherotar} ${fichero} 2>> ${logFile} 1>> ${logFile}
      openssl enc -aes-256-cbc -pass file:${cryptloc}/key.txt -in ${ficherotar} -out ${cryptloc}${ficherotar}.encrypted 2>> ${logFile} 1>> ${logFile}
      rm -rf ${ficherotar}
    fi
  done <${hostBackupDirs}
  openssl rsautl -encrypt -in ${cryptloc}/key.txt -out ${cryptloc}/key.encrypted -inkey ${configFiles}backup.pub.pem -pubin 2>> ${logFile} 1>> ${logFile}
  rm ${cryptloc}/key.txt
}

###	full backup
# genera una copia completa y un snapshot sobre el que realizar las copias incrementales

if [ "${BackupType}" == "full" ]; then
        backupFile=${host}-full-${date}.tar.gz
        echo "Tipo de backup: FULL" | tee -a ${logFile}
        if [ -f ${BackupLoc}/${snapshot} ]; then
                echo "Encontrado snapshot, generando uno nuevo.." | tee -a ${logFile}
                rm ${BackupLoc}/${snapshot}
        fi
        makeBackup
fi

###   incremental backup
# genera copias incrementales sobre un snapshot previamente creado

if [ "${BackupType}" == "incremental" ]; then
        backupFile=${host}-incremental-${date}.tar.gz
        echo "Tipo de backup: INCREMENTAL" | tee -a ${logFile}
        if [ ! -f ${BackupLoc}/${snapshot} ]; then
                echo "ERROR: Snapshot no encontrado, crear un backup completo antes" | tee -a ${logFile}
                exit 1
        fi
        makeBackup
fi


###   diferencial backup
# genera copias diferenciales desde la fecha de la ultima copia (fecha registrada en lastbackup.txt (no usar junto a incrementales con esta configuracion))

# if [ "${BackupType}" == "diferencial" ]; then
#         backupFile=$(hostname)-${date}-diferencial.tar.gz
#         mkdir ${BackupLoc}/${nombreBackup}
#         echo "Tipo de backup: DIFERENCIAL" | tee -a ${logFile}
#         tar -cvpzf ${BackupLoc}/${nombreBackup}/${backupFile} -N ${BackupLoc}/lastbackup.txt $(cat ${hostBackupDirs} | paste -sd " " -) 2>> ${logFile} 1>> ${logFile}
#         if [[ $? = 0 ]]; then
#                 echo "Backup realizado: ${backupFile}" | tee -a ${logFile}
#         else
#                 echo "Backup no realizado" | tee -a ${logFile}
#                 mail -s "error de backup" ${email} < ${logFile}
#                 exit 1
#         fi
# fi

###	rsync
# usa un par de claves sin frase de paso creadas previamente

if [ "$2" == "remote" ]; then
        echo "Sincronizando con servidor remoto: ${remoteHost}" | tee -a ${logFile}
        rsync --delete-after -a -e "ssh -i ~/.ssh/backup" ${BackupLoc}/${nombreBackup} ${remoteUser}@${remoteHost}:$remoteDir 2>> ${logFile} 1>> ${logFile}
        if [[ $? = 0 ]]; then
                echo "Sincronizacion realizada" | tee -a ${logFile}
                insercionCoconut
        else
                echo "Sincronizacion fallida" | tee -a ${logFile}
                mail -s "error de backup" ${email} < ${logFile}
        fi
fi

#T O D O

# estudiar diferencias del parametro de rsync --delete
# asignar nombres de variables mas claros
# añadir al readme los pasos no mostrados aqui (documentacion general (usar tarea redmine), creacion de ~/.pgpass para insertar en coconut, creacion de pares de claves tanto para la encriptacion como la conexion remota)
# modificar copias diferenciales para usar solo sobre copias completas
