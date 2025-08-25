#!/bin/bash

# Script de backup automático para todas las bases de datos
# Se ejecuta periódicamente via cron

BACKUP_DIR="/backups/auto"
DATE=$(date +"%Y%m%d_%H%M%S")

# Crear directorio de backups automáticos si no existe
mkdir -p "$BACKUP_DIR"

echo "[BACKUP] Iniciando backup automático - $DATE"

# Función para limpiar backups antiguos (mantener solo los últimos 7 días)
cleanup_old_backups() {
    local db_type=$1
    echo "[BACKUP] Limpiando backups antiguos de $db_type..."
    find "$BACKUP_DIR" -name "*_${db_type}_*" -type f -mtime +7 -delete
}

# Backup PostgreSQL
if command -v pg_dump &> /dev/null; then
    echo "[BACKUP] Realizando backup de PostgreSQL..."
    
    # Obtener lista de bases de datos
    databases=$(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")
    
    for db in $databases; do
        db=$(echo $db | xargs)  # Trim whitespace
        if [ ! -z "$db" ]; then
            backup_file="$BACKUP_DIR/${DATE}_postgresql_${db}.sql"
            pg_dump -U postgres "$db" > "$backup_file"
            
            if [ $? -eq 0 ]; then
                echo "[BACKUP] ✅ PostgreSQL: $db -> $backup_file"
            else
                echo "[BACKUP] ❌ Error en backup de PostgreSQL: $db"
                rm -f "$backup_file"
            fi
        fi
    done
    
    cleanup_old_backups "postgresql"
fi

# Backup MySQL
if command -v mysqldump &> /dev/null; then
    echo "[BACKUP] Realizando backup de MySQL..."
    
    # Obtener lista de bases de datos
    databases=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;" | grep -v -E '^(Database|information_schema|performance_schema|mysql|sys)$')
    
    for db in $databases; do
        if [ ! -z "$db" ]; then
            backup_file="$BACKUP_DIR/${DATE}_mysql_${db}.sql"
            mysqldump -u root -p$MYSQL_ROOT_PASSWORD "$db" > "$backup_file"
            
            if [ $? -eq 0 ]; then
                echo "[BACKUP] ✅ MySQL: $db -> $backup_file"
            else
                echo "[BACKUP] ❌ Error en backup de MySQL: $db"
                rm -f "$backup_file"
            fi
        fi
    done
    
    cleanup_old_backups "mysql"
fi

# Backup MongoDB
if command -v mongodump &> /dev/null; then
    echo "[BACKUP] Realizando backup de MongoDB..."
    
    # Obtener lista de bases de datos
    databases=$(mongosh --quiet --eval "db.adminCommand('listDatabases').databases.forEach(function(d){if(d.name!='admin'&&d.name!='local'&&d.name!='config')print(d.name)})")
    
    for db in $databases; do
        if [ ! -z "$db" ]; then
            backup_dir="$BACKUP_DIR/${DATE}_mongodb_${db}"
            mongodump --db "$db" --out "$backup_dir"
            
            if [ $? -eq 0 ]; then
                # Comprimir el directorio
                tar -czf "${backup_dir}.tar.gz" -C "$BACKUP_DIR" "$(basename "$backup_dir")"
                rm -rf "$backup_dir"
                echo "[BACKUP] ✅ MongoDB: $db -> ${backup_dir}.tar.gz"
            else
                echo "[BACKUP] ❌ Error en backup de MongoDB: $db"
                rm -rf "$backup_dir"
            fi
        fi
    done
    
    cleanup_old_backups "mongodb"
fi

# Backup SQL Server
if command -v sqlcmd &> /dev/null; then
    echo "[BACKUP] Realizando backup de SQL Server..."
    
    # Obtener lista de bases de datos
    databases=$(/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -h -1 -Q "SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb');")
    
    for db in $databases; do
        db=$(echo $db | xargs)  # Trim whitespace
        if [ ! -z "$db" ]; then
            backup_file="$BACKUP_DIR/${DATE}_sqlserver_${db}.bak"
            /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "BACKUP DATABASE [$db] TO DISK = '$backup_file' WITH FORMAT, INIT;"
            
            if [ $? -eq 0 ]; then
                echo "[BACKUP] ✅ SQL Server: $db -> $backup_file"
            else
                echo "[BACKUP] ❌ Error en backup de SQL Server: $db"
                rm -f "$backup_file"
            fi
        fi
    done
    
    cleanup_old_backups "sqlserver"
fi

echo "[BACKUP] Backup automático completado - $DATE"

# Mostrar resumen de archivos creados
echo "[BACKUP] Archivos de backup creados:"
ls -la "$BACKUP_DIR" | grep "$DATE"