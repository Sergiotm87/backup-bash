#!/bin/bash
#
#script para realizar backups completos,incrementales y diferenciales
#
#ejecucion: backup-bash.sh [full|incremental|diferencial] [remote]

###	variables
host=$(hostname)
BackupLoc=/opt/backup
BackupType="$1"
date=$(date +%Y-%m-%d)
logFile=$BackupLoc/logs/$host-$date.log
snapBackup=$host.snar
hostBackupDirs=/etc/backups/hosts/$host
remoteDir=/home/debian/backups
remoteHost=172.22.200.225
remoteUser=debian
email=sergiotm87@gmail.com

###	comprobaciones
# directorio de backups
if [ ! -d $BackupLoc ]; then
        echo "Creando Directorio: $BackupLoc"
        mkdir -p $BackupLoc/logs/
fi
# tipo de backup
if [[ "$BackupType" != "full" && "$BackupType" != "incremental" && "$BackupType" != "diferencial" ]]; then
        echo "ERROR: Argumentos invalidos" | tee -a $logFile
        echo "Ejecutar como <full>, <incremental> o <diferencial>" | tee -a $logFile
        exit 1
fi
# existe el fichero de directorios del host con los directorios a los que realizar backup
if [ ! -f $hostBackupDirs ]; then
        echo "ERROR: no existe el fichero $hostBackupDirs" | tee -a $logFile
        echo "Especificar a que directorios realizar backup" | tee -a $logFile
        exit 1
fi

function makeBackup(){
  echo "Ejecutando Backup" | tee -a $logFile
  mkdir $BackupLoc/$host-$BackupType-$date
  tar --listed-incremental=$BackupLoc/$snapBackup -cvpzf $BackupLoc/$host-$BackupType-$date/$backupFile $(cat $hostBackupDirs | paste -sd " " -) 2>> $logFile 1>> $logFile
  if [[ $? = 0 ]]; then
          echo "Backup realizado: $backupFile" | tee -a $logFile
          date > $BackupLoc/lastbackup.txt | tee -a $logFile
  else
          echo "Backup no realizado" | tee -a $logFile
          mail -s "error de backup" $email < $logFile
          exit 1
  fi
}


function insercionCoconut(){
  echo "Insercion en Coconut" | tee -a $logFile
}

###	full backup
# genera una copia completa y un snapshot sobre el que realizar las copias incrementales

if [ "$BackupType" == "full" ]; then
        backupFile=$host-full-$date.tar.gz
        echo "Tipo de backup: FULL" | tee -a $logFile
        if [ -f $BackupLoc/$snapBackup ]; then
                echo "Encontrado snapshot, generando uno nuevo.." | tee -a $logFile
                rm $BackupLoc/$snapBackup
        fi
        makeBackup
fi

###   incremental backup
# genera copias incrementales sobre un snapshot previamente creado

if [ "$BackupType" == "incremental" ]; then
        backupFile=$host-incremental-$date.tar.gz
        echo "Tipo de backup: INCREMENTAL" | tee -a $logFile
        if [ ! -f $BackupLoc/$snapBackup ]; then
                echo "ERROR: Snapshot no encontrado, crear un backup completo antes" | tee -a $logFile
                exit 1
        fi
        makeBackup
fi


###   diferencial backup
# genera copias diferenciales desde la fecha del ultimo backup completo/incremental

if [ "$BackupType" == "diferencial" ]; then
        backupFile=$(hostname)-$date-diferencial.tar.gz
        mkdir $BackupLoc/$host-$BackupType-$date
        echo "Tipo de backup: DIFERENCIAL" | tee -a $logFile
        tar -cvpzf $BackupLoc/$host-$BackupType-$date/$backupFile -N $BackupLoc/lastbackup.txt $(cat $hostBackupDirs | paste -sd " " -) 2>> $logFile 1>> $logFile
        if [[ $? = 0 ]]; then
                echo "Backup realizado: $backupFile" | tee -a $logFile
        else
                echo "Backup no realizado" | tee -a $logFile
                mail -s "error de backup" $email < $logFile
                exit 1
        fi
fi

###	rsync

if [ "$2" == "remote" ]; then
        echo "Sincronizando con servidor remoto: $servidorRemoto" | tee -a $logFile
        rsync -a $BackupLoc/$host-$date-$BackupType/$backupFile $remoteUser@$remoteHost:$remoteDir 2>> $logFile 1>> $logFile
        #rsync --delete-before -avze "ssh -i $DST_RMT_CERT" $BackupLoc/ $DST_RMT_USER@$servidorRemoto:$remoteDir 2>> $LOG 1>> $LOG
        if [[ $? = 0 ]]; then
                echo "Sincronizacion realizada" | tee -a $logFile
                #
                # realizar insercion en coconut
                #
        else
                echo "Sincronizacion fallida" | tee -a $logFile
                mail -s "error de backup" $email < $logFile
        fi
fi
