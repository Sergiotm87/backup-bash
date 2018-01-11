#  backup-bash

###  Tarea de sistemas del modulo ASIR

El sistema de copias de seguridad ha sido realizado con un shell script haciendo uso de tar y rsync permitiendo realizar copias completas, incrementales o diferenciales.

Se usan timers y services de systemD para ejecutarlo mediante la instrucción 
```sh
$ backup-bash.sh full|incremental|diferencial [remote]
```


Para utilizarlo se debe modificar:
- los ficheros en /etc/backups/hosts para decidir que directorios incluir en la copia
- crear/ajustar las unidades de systemD en /etc/systemd/system/ para el tipo de copia y el calendario de ejecución de estas

Mediante un pequeño script de instalación se colocan los componentes del sistema en el host (timers, services, script y fichero del host), el código del script principal es el mismo para cada host y cada uno tiene un documento en el que se detallan los directorios que se añaden a la copia y si alguno de estos debe ser encriptado. La encriptación se realiza mediante clave simétrica (generada en cada copia) que se envía junto con los ficheros al volumen de almacenamiento. Ésta a su vez se encripta con una clave asimétrica que se encuentra en los nodos y en mi equipo personal. Los ficheros se desencriptan mediante otro script y la restauración se realiza manualmente.

Se ha dejado una zona de variables al inicio del script para realizar los cambios necesarios en cada escenario y que el código sea lo más reutilizable posible. Según lo vaya utilizando se detectarán las mejoras/cambios oportunos.

Cuando se realiza una copia completa o incremental en cada nodo se genera un snapshot en el host para agilizar las siguientes copias incrementales y durante todo el proceso se genera un log con cada instrucción realizada que se envía por correo en caso de error.

Una vez realizada la sincronización externa con éxito se realiza la inserción en una base de datos postgres con una aplicación web para hacer el seguimiento de las copias.

Ejemplo de log del sistema tras realización de copia completa:

```sh
$ journalctl -u backupfull.service*

Jan 11 19:29:02 minnie systemd [1]: Started Crear backup completo.
Jan 11 19:29:02 minnie bash [29689]: Tipo de backup: FULL
Jan 11 19:29:02 minnie bash [29689]: Encontrado snapshot, generando uno nuevo..
Jan 11 19:29:02 minnie bash [29689]: Ejecutando Backup
Jan 11 19:29:02 minnie bash [29689]: Encriptando ficheros marcados
Jan 11 19:29:05 minnie bash [29689]: Backup realizado: minnie-full-2018-01-11.tar.gz
Jan 11 19:29:05 minnie bash [29689]: Sincronizando con servidor remoto: 172.22.200.42
Jan 11 19:29:06 minnie bash [29689]: Sincronizacion realizada
Jan 11 19:29:06 minnie bash [29689]: Insercion en Coconut..
Jan 11 19:29:06 minnie bash [29689]: Insercion realizada: minnie-full-2018-01-11.tar.gz
```

