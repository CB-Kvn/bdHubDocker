#!/bin/bash
# Script de restauración para PostgreSQL
# Uso: ./restore_postgresql.sh nombre_base_datos archivo_backup.sql

# Verificar parámetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 <nombre_base_datos> <archivo_backup>"
    echo "Ejemplo: $0 mi_db backup.sql"
    echo "Ejemplo: $0 mi_db backup.dump (para archivos binarios)"
    exit 1
fi

DB_NAME=$1
BACKUP_FILE=$2
BACKUP_PATH="/backups/$BACKUP_FILE"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Error: El archivo $BACKUP_PATH no existe"
    exit 1
fi

echo "Restaurando base de datos: $DB_NAME"
echo "Desde archivo: $BACKUP_PATH"

# Determinar el tipo de archivo y restaurar
if [[ "$BACKUP_FILE" == *.sql ]]; then
    echo "Restaurando desde archivo SQL..."
    # Crear la base de datos si no existe
    createdb -U postgres "$DB_NAME" 2>/dev/null || echo "Base de datos ya existe o error al crear"
    # Restaurar desde SQL
    psql -U postgres -d "$DB_NAME" -f "$BACKUP_PATH"
elif [[ "$BACKUP_FILE" == *.dump ]] || [[ "$BACKUP_FILE" == *.backup ]]; then
    echo "Restaurando desde archivo binario..."
    # Crear la base de datos si no existe
    createdb -U postgres "$DB_NAME" 2>/dev/null || echo "Base de datos ya existe o error al crear"
    # Restaurar desde dump binario
    pg_restore -U postgres -d "$DB_NAME" -v "$BACKUP_PATH"
else
    echo "Error: Tipo de archivo no soportado. Use .sql, .dump o .backup"
    exit 1
fi

echo "Restauración completada para $DB_NAME"

# Comandos de ejemplo para ejecutar desde el host:
# docker-compose exec postgresql bash /backups/restore_postgresql.sh mi_db backup.sql
# docker-compose exec postgresql bash /backups/restore_postgresql.sh mi_db backup.dump