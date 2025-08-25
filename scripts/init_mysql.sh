#!/bin/bash

# Script de inicialización automática para MySQL
# Se ejecuta al crear el contenedor

echo "[INIT] Iniciando configuración automática de MySQL..."

# Esperar a que MySQL esté listo
echo "[INIT] Esperando a que MySQL esté disponible..."
until mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD --silent; do
  echo "[INIT] MySQL no está listo, esperando..."
  sleep 2
done

echo "[INIT] MySQL está listo!"

# Buscar archivos de backup en el directorio /backups
if [ -d "/backups" ] && [ "$(ls -A /backups/*.sql 2>/dev/null)" ]; then
    echo "[INIT] Archivos de backup encontrados, iniciando restauración..."
    
    for backup_file in /backups/*.sql; do
        if [ -f "$backup_file" ]; then
            # Extraer nombre de la base de datos del archivo
            db_name=$(basename "$backup_file" .sql)
            
            echo "[INIT] Restaurando $backup_file en base de datos: $db_name"
            
            # Crear la base de datos si no existe
            mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            
            # Restaurar el backup
            mysql -u root -p$MYSQL_ROOT_PASSWORD "$db_name" < "$backup_file"
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Backup $backup_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar $backup_file"
            fi
        fi
    done
else
    echo "[INIT] No se encontraron archivos de backup para MySQL"
fi

echo "[INIT] Configuración automática de MySQL completada"