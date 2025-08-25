#!/bin/bash

# Script de inicialización automática para SQL Server
# Se ejecuta al crear el contenedor

echo "[INIT] Iniciando configuración automática de SQL Server..."

# Esperar a que SQL Server esté listo
echo "[INIT] Esperando a que SQL Server esté disponible..."
# Usar sqlcmd desde el PATH (enlace simbólico creado en Dockerfile)
until sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C > /dev/null 2>&1; do
  echo "[INIT] SQL Server no está listo, esperando..."
  sleep 5
done

echo "[INIT] SQL Server está listo!"

# Buscar archivos de backup en el directorio /backups
if [ -d "/backups" ] && [ "$(ls -A /backups/*.bak 2>/dev/null)" ]; then
    echo "[INIT] Archivos de backup encontrados, iniciando restauración..."
    
    for backup_file in /backups/*.bak; do
        if [ -f "$backup_file" ]; then
            # Extraer nombre de la base de datos del archivo
            db_name=$(basename "$backup_file" .bak)
            
            echo "[INIT] Restaurando $backup_file en base de datos: $db_name"
            
            # Obtener información del backup y extraer nombres de archivos lógicos
            data_file=$(sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "RESTORE FILELISTONLY FROM DISK = '/backups/$(basename "$backup_file")';" -h -1 -W -C | grep -E "\s+D\s+" | awk '{print $1}' | head -1)
            log_file=$(sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "RESTORE FILELISTONLY FROM DISK = '/backups/$(basename "$backup_file")';" -h -1 -W -C | grep -E "\s+L\s+" | awk '{print $1}' | head -1)
            
            echo "[INIT] Archivos lógicos detectados: DATA=$data_file, LOG=$log_file"
            
            # Restaurar el backup con REPLACE para sobrescribir si existe
            sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "
                RESTORE DATABASE [$db_name] 
                FROM DISK = '/backups/$(basename "$backup_file")' 
                WITH REPLACE,
                MOVE '$data_file' TO '/var/opt/mssql/data/${db_name}.mdf',
                MOVE '$log_file' TO '/var/opt/mssql/data/${db_name}_Log.ldf';
            " -C
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Backup $backup_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar $backup_file, intentando restauración simple..."
                
                # Intentar restauración más simple
                sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "
                    RESTORE DATABASE [$db_name] 
                    FROM DISK = '/backups/$(basename "$backup_file")' 
                    WITH REPLACE;
                " -C
                
                if [ $? -eq 0 ]; then
                    echo "[INIT] ✅ Backup $backup_file restaurado exitosamente (método simple)"
                else
                    echo "[INIT] ❌ Error al restaurar $backup_file con ambos métodos"
                fi
            fi
        fi
    done
else
    echo "[INIT] No se encontraron archivos de backup (.bak) para SQL Server"
fi

echo "[INIT] Configuración automática de SQL Server completada"