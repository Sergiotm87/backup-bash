#!/bin/bash

#script para realizar backups completos e incrementales

#ejecucion: backup-bash.sh [full|incremental]

###	variables

Backup=/home/sergio/github/backup-bash/bin/www

BackupLoc=/opt/backup

BackupType="$1"

echo $BackupType

date=$(date +%m-%d-%Y_%H-%M)

logFile=$BackupLoc-$date.log

###	comprobaciones

# comprobar tipo de backup
if [ "$#" -ne 1 ]; then
    echo "ERROR: Cantidad de argumentos nvalidos." | tee -a $logFile
exit 1
fi
if [[ "$BackupType" != "full" && "$BackupType" != "incremental" ]]; then
        echo "ERROR: Argumentos invalidos" | tee -a $logFile
        echo "Ejecutar como <full> o <incremental>" | tee -a $logFile
        exit 1
fi

# comprobar que existe el directorio de backups
if [ ! -d $BackupLoc ]; then 
        echo "Creando Directorio: $BackupLoc" | tee -a $logFile
        mkdir -p $BackupLoc 2>> $logFile 1>> $logFile
fi

###	full backup

# genera un snapshot sobre el que realizar las copias incrementales, si encuentra uno previamente creado
# lo mueve a un nuevo directorio

if [ "$BackupType" == "full" ]; then
        backupFile=$(hostname)-$date-full.tar
        snapBackup=$(hostname)-full.snap
        echo "Tipo de backup: FULL" | tee -a $logFile
        echo "" | tee -a $logFile
        if [ -f $BackupLoc/$snapBackup ]; then
                echo " Encontrado snapshot " | tee -a $logFile
                echo " Moviendo a: $BackupLoc/FULL-$date/" | tee -a $logFile
                mkdir $BackupLoc/FULL-$date/ 2>> $logFile 1>> $logFile
                mv $BackupLoc/$snapBackup $BackupLoc/FULL-$date/ 2>> $logFile 1>> $logFile
                mv $BackupLoc/*.tar $BackupLoc/FULL-$date/ 2>> $logFile 1>> $logFile
                #mv $BackupLoc/*.log  $BackupLoc/FULL-$date/ 2>> $logFile 1>> $logFile
                echo "" | tee -a $logFile
        fi
        echo " Ejecutando Backup" | tee -a $logFile
        tar --listed-incremental=$BackupLoc/$snapBackup -cvpzf $BackupLoc/$backupFile "$Backup/" 2>> $logFile 1>> $logFile
        if [[ $? = 0 ]]; then
                echo "Backup realizado" | tee -a $logFile
        else
                echo "Backup no realizado" | tee -a $logFile
        fi
fi

###   incremental backup

# genera copias incrementales sobre un snapshot previamente creado (termina la ejecución si no se encuentra)

###	rsync

# envia el fichero generado a un directorio remoto
