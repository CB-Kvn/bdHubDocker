#!/bin/bash

# Script de inicialización automática para PostgreSQL
# Se ejecuta al crear el contenedor

echo "[INIT] Iniciando configuración automática de PostgreSQL..."

# Esperar a que PostgreSQL esté listo
echo "[INIT] Esperando a que PostgreSQL esté disponible..."
until pg_isready -h localhost -p 5432 -U postgres; do
  echo "[INIT] PostgreSQL no está listo, esperando..."
  sleep 2
done

echo "[INIT] PostgreSQL está listo!"

# Buscar archivos de backup en el directorio /backups
if [ -d "/backups" ] && [ "$(ls -A /backups/*.sql 2>/dev/null)" ]; then
    echo "[INIT] Archivos de backup encontrados, iniciando restauración..."
    
    for backup_file in /backups/*.sql; do
        if [ -f "$backup_file" ]; then
            # Extraer nombre de la base de datos del archivo
            db_name=$(basename "$backup_file" .sql)
            
            echo "[INIT] Restaurando $backup_file en base de datos: $db_name"
            
            # Crear la base de datos si no existe
            psql -U postgres -c "CREATE DATABASE \"$db_name\" WITH ENCODING='UTF8';"
            
            # Restaurar el backup
            psql -U postgres -d "$db_name" -f "$backup_file"
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Backup $backup_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar $backup_file"
            fi
        fi
    done
    
    # Buscar archivos .dump o .backup
    for backup_file in /backups/*.dump /backups/*.backup; do
        if [ -f "$backup_file" ]; then
            db_name=$(basename "$backup_file" | sed 's/\.[^.]*$//')
            
            echo "[INIT] Restaurando dump binario $backup_file en base de datos: $db_name"
            
            # Crear la base de datos si no existe
            psql -U postgres -c "CREATE DATABASE \"$db_name\" WITH ENCODING='UTF8';"
            
            # Restaurar el dump binario
            pg_restore -U postgres -d "$db_name" "$backup_file"
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Dump $backup_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar $backup_file"
            fi
        fi
    done
else
    echo "[INIT] No se encontraron archivos de backup para PostgreSQL"
fi

echo "[INIT] Configuración automática de PostgreSQL completada"