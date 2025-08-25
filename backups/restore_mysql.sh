#!/bin/bash
# Script de restauración para MySQL
# Uso: ./restore_mysql.sh nombre_base_datos archivo_backup.sql

# Verificar parámetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 <nombre_base_datos> <archivo_backup.sql>"
    echo "Ejemplo: $0 mi_db backup.sql"
    exit 1
fi

DB_NAME=$1
BACKUP_FILE=$2
BACKUP_PATH="/backups/$BACKUP_FILE"
MYSQL_ROOT_PASSWORD="root123"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Error: El archivo $BACKUP_PATH no existe"
    exit 1
fi

echo "Restaurando base de datos MySQL: $DB_NAME"
echo "Desde archivo: $BACKUP_PATH"

# Crear la base de datos si no existe
echo "Creando base de datos si no existe..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

if [ $? -eq 0 ]; then
    echo "Base de datos $DB_NAME lista"
else
    echo "Error al crear/verificar la base de datos"
    exit 1
fi

# Restaurar desde el archivo SQL
echo "Restaurando datos..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$DB_NAME" < "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "Restauración completada exitosamente para $DB_NAME"
else
    echo "Error durante la restauración"
    exit 1
fi

# Mostrar información de la base de datos restaurada
echo "Verificando tablas en la base de datos restaurada:"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $DB_NAME; SHOW TABLES;"

echo "Restauración de MySQL completada"

# Comandos de ejemplo para ejecutar desde el host:
# docker-compose exec mysql bash /backups/restore_mysql.sh mi_db backup.sql
# 
# Para crear un backup:
# docker-compose exec mysql mysqldump -u root -proot123 nombre_db > /backups/backup_$(date +%Y%m%d_%H%M%S).sql