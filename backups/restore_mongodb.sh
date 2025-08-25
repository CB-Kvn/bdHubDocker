#!/bin/bash
# Script de restauración para MongoDB
# Uso: ./restore_mongodb.sh nombre_base_datos archivo_backup

# Verificar parámetros
if [ $# -lt 2 ]; then
    echo "Uso: $0 <nombre_base_datos> <archivo_o_directorio_backup> [coleccion]"
    echo "Ejemplos:"
    echo "  $0 mi_db backup.json coleccion_name    # Restaurar JSON a colección específica"
    echo "  $0 mi_db backup_directory              # Restaurar desde directorio de mongodump"
    echo "  $0 mi_db backup.bson coleccion_name    # Restaurar BSON a colección específica"
    exit 1
fi

DB_NAME=$1
BACKUP_SOURCE=$2
COLLECTION_NAME=$3
BACKUP_PATH="/backups/$BACKUP_SOURCE"
MONGO_USER="admin"
MONGO_PASSWORD="admin123"

# Verificar que el archivo o directorio existe
if [ ! -e "$BACKUP_PATH" ]; then
    echo "Error: $BACKUP_PATH no existe"
    exit 1
fi

echo "Restaurando base de datos MongoDB: $DB_NAME"
echo "Desde: $BACKUP_PATH"

# Función para restaurar desde directorio (mongodump)
restore_from_directory() {
    echo "Restaurando desde directorio de mongodump..."
    mongorestore --host localhost:27017 \
                 --username "$MONGO_USER" \
                 --password "$MONGO_PASSWORD" \
                 --authenticationDatabase admin \
                 --db "$DB_NAME" \
                 --drop \
                 "$BACKUP_PATH"
}

# Función para restaurar desde archivo JSON
restore_from_json() {
    if [ -z "$COLLECTION_NAME" ]; then
        echo "Error: Para archivos JSON debe especificar el nombre de la colección"
        exit 1
    fi
    
    echo "Restaurando JSON a colección: $COLLECTION_NAME"
    mongoimport --host localhost:27017 \
                --username "$MONGO_USER" \
                --password "$MONGO_PASSWORD" \
                --authenticationDatabase admin \
                --db "$DB_NAME" \
                --collection "$COLLECTION_NAME" \
                --file "$BACKUP_PATH" \
                --jsonArray \
                --drop
}

# Función para restaurar desde archivo BSON
restore_from_bson() {
    if [ -z "$COLLECTION_NAME" ]; then
        echo "Error: Para archivos BSON debe especificar el nombre de la colección"
        exit 1
    fi
    
    echo "Restaurando BSON a colección: $COLLECTION_NAME"
    mongorestore --host localhost:27017 \
                 --username "$MONGO_USER" \
                 --password "$MONGO_PASSWORD" \
                 --authenticationDatabase admin \
                 --db "$DB_NAME" \
                 --collection "$COLLECTION_NAME" \
                 --drop \
                 "$BACKUP_PATH"
}

# Determinar el tipo de restauración
if [ -d "$BACKUP_PATH" ]; then
    # Es un directorio
    restore_from_directory
elif [[ "$BACKUP_SOURCE" == *.json ]]; then
    # Es un archivo JSON
    restore_from_json
elif [[ "$BACKUP_SOURCE" == *.bson ]]; then
    # Es un archivo BSON
    restore_from_bson
else
    echo "Error: Tipo de archivo no reconocido. Use .json, .bson o un directorio de mongodump"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Restauración completada exitosamente para $DB_NAME"
    
    # Mostrar colecciones en la base de datos
    echo "Colecciones en la base de datos restaurada:"
    mongosh --host localhost:27017 \
            --username "$MONGO_USER" \
            --password "$MONGO_PASSWORD" \
            --authenticationDatabase admin \
            --eval "use $DB_NAME; show collections"
else
    echo "Error durante la restauración"
    exit 1
fi

echo "Restauración de MongoDB completada"

# Comandos de ejemplo para ejecutar desde el host:
# docker-compose exec mongodb bash /backups/restore_mongodb.sh mi_db backup.json mi_coleccion
# docker-compose exec mongodb bash /backups/restore_mongodb.sh mi_db backup_directory
# 
# Para crear backups:
# docker-compose exec mongodb mongodump --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db mi_db --out /backups/
# docker-compose exec mongodb mongoexport --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db mi_db --collection mi_coleccion --out /backups/backup.json --jsonArray