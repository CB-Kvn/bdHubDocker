#!/bin/bash

# Script de inicialización automática para MongoDB
# Se ejecuta al crear el contenedor

echo "[INIT] Iniciando configuración automática de MongoDB..."

# Esperar a que MongoDB esté listo
echo "[INIT] Esperando a que MongoDB esté disponible..."
until mongosh --eval "db.adminCommand('ping')" --quiet; do
  echo "[INIT] MongoDB no está listo, esperando..."
  sleep 2
done

echo "[INIT] MongoDB está listo!"

# Buscar archivos de backup en el directorio /backups
if [ -d "/backups" ]; then
    echo "[INIT] Verificando archivos de backup..."
    
    # Restaurar desde directorios de mongodump
    for dump_dir in /backups/*/; do
        if [ -d "$dump_dir" ] && [ "$(ls -A "$dump_dir" 2>/dev/null)" ]; then
            db_name=$(basename "$dump_dir")
            echo "[INIT] Restaurando dump de directorio: $dump_dir para base de datos: $db_name"
            
            mongorestore --db "$db_name" "$dump_dir"
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Dump de directorio $dump_dir restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar dump de directorio $dump_dir"
            fi
        fi
    done
    
    # Restaurar archivos JSON individuales
    for json_file in /backups/*.json; do
        if [ -f "$json_file" ]; then
            # Extraer nombre de base de datos y colección del archivo
            filename=$(basename "$json_file" .json)
            
            # Formato esperado: database_collection.json
            if [[ "$filename" == *"_"* ]]; then
                db_name=$(echo "$filename" | cut -d'_' -f1)
                collection_name=$(echo "$filename" | cut -d'_' -f2-)
            else
                db_name="$filename"
                collection_name="data"
            fi
            
            echo "[INIT] Restaurando $json_file en base de datos: $db_name, colección: $collection_name"
            
            mongoimport --db "$db_name" --collection "$collection_name" --file "$json_file" --jsonArray
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Archivo JSON $json_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar archivo JSON $json_file"
            fi
        fi
    done
    
    # Restaurar archivos BSON individuales
    for bson_file in /backups/*.bson; do
        if [ -f "$bson_file" ]; then
            filename=$(basename "$bson_file" .bson)
            
            if [[ "$filename" == *"_"* ]]; then
                db_name=$(echo "$filename" | cut -d'_' -f1)
                collection_name=$(echo "$filename" | cut -d'_' -f2-)
            else
                db_name="$filename"
                collection_name="data"
            fi
            
            echo "[INIT] Restaurando $bson_file en base de datos: $db_name, colección: $collection_name"
            
            mongorestore --db "$db_name" --collection "$collection_name" "$bson_file"
            
            if [ $? -eq 0 ]; then
                echo "[INIT] ✅ Archivo BSON $bson_file restaurado exitosamente"
            else
                echo "[INIT] ❌ Error al restaurar archivo BSON $bson_file"
            fi
        fi
    done
    
    if [ ! "$(ls -A /backups/*.json /backups/*.bson /backups/*/ 2>/dev/null)" ]; then
        echo "[INIT] No se encontraron archivos de backup para MongoDB"
    fi
else
    echo "[INIT] Directorio /backups no encontrado"
fi

echo "[INIT] Configuración automática de MongoDB completada"