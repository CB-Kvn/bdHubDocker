# Multi-Database Docker Hub

Este proyecto proporciona un entorno Docker con 5 bases de datos diferentes ejecutándose simultáneamente en puertos separados.

## Bases de Datos Incluidas

- **SQL Server** (Puerto 1433)
- **PostgreSQL** (Puerto 5432)
- **MongoDB** (Puerto 27017)
- **DynamoDB Local** (Puerto 8000)
- **MySQL** (Puerto 3306)
- **Adminer** - Interfaz web para gestión de BD (Puerto 8080)

## Requisitos Previos

- Docker Desktop instalado
- Docker Compose instalado
- Al menos 4GB de RAM disponible
- Puertos 1433, 3306, 5432, 8000, 8080 y 27017 libres

## 🚀 Instalación y Uso

### Prerrequisitos
- Docker
- Docker Compose

### Pasos de instalación

1. **Clonar o descargar** este repositorio
2. **Navegar** al directorio del proyecto
3. **Construir y ejecutar** los contenedores:
   ```bash
   docker-compose up -d --build
   ```
   > **Nota**: El flag `--build` es necesario para construir las imágenes personalizadas con automatización

4. **Esperar** a que todos los contenedores se inicien correctamente (puede tomar varios minutos en la primera ejecución)
5. **Verificar** el estado de los contenedores:
   ```bash
   docker-compose ps
   ```

### ⚡ Características de Automatización

#### 🔄 Restauración Automática al Inicio
- **Los contenedores automáticamente restauran** cualquier backup encontrado en `./backups/` al iniciarse
- **Formatos soportados**:
  - SQL Server: `.bak`
  - PostgreSQL: `.sql`, `.dump`, `.backup`
  - MySQL: `.sql`
  - MongoDB: directorios de `mongodump`, `.json`, `.bson`

#### 📅 Backups Automáticos Programados
- **Backup diario**: Todos los días a las 2:00 AM
- **Backup semanal**: Domingos a las 3:00 AM
- **Limpieza automática**: Mantiene solo los últimos 7 días de backups
- **Logs detallados**: Guardados en `/var/log/backup/` dentro de cada contenedor

### Comandos Básicos

#### Detener todos los servicios
```bash
docker-compose down
```

#### Detener y eliminar volúmenes (CUIDADO: Elimina todos los datos)
```bash
docker-compose down -v
```

## Información de Conexión

### SQL Server
- **Host:** localhost
- **Puerto:** 1433
- **Usuario:** sa
- **Contraseña:** YourStrong@Passw0rd
- **Cadena de conexión:** `Server=localhost,1433;Database=master;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=true;`

### PostgreSQL
- **Host:** localhost
- **Puerto:** 5432
- **Base de datos:** postgres
- **Usuario:** postgres
- **Contraseña:** postgres123
- **Cadena de conexión:** `postgresql://postgres:postgres123@localhost:5432/postgres`

### MongoDB
- **Host:** localhost
- **Puerto:** 27017
- **Usuario:** admin
- **Contraseña:** admin123
- **Cadena de conexión:** `mongodb://admin:admin123@localhost:27017/`

### MySQL
- **Host:** localhost
- **Puerto:** 3306
- **Base de datos:** testdb
- **Usuario:** user (o root)
- **Contraseña:** user123 (o root123 para root)
- **Cadena de conexión:** `mysql://user:user123@localhost:3306/testdb`

### DynamoDB Local
- **Host:** localhost
- **Puerto:** 8000
- **Endpoint:** http://localhost:8000
- **Región:** us-east-1 (para configuración local)
- **Access Key:** cualquier valor (para desarrollo local)
- **Secret Key:** cualquier valor (para desarrollo local)

### Adminer (Interfaz Web)
- **URL:** http://localhost:8080
- Puedes conectarte a cualquiera de las bases de datos SQL desde esta interfaz

## Backup y Restauración

### Directorio de Backups
Todos los contenedores tienen acceso a la carpeta `./backups` que se monta como `/backups` dentro de cada contenedor. Coloca tus archivos de backup en esta carpeta para poder restaurarlos.

### SQL Server
**Crear Backup:**
```bash
# Desde SQL Server Management Studio o sqlcmd
BACKUP DATABASE [NombreDB] TO DISK = '/backups/backup_sqlserver.bak'
```

**Restaurar Backup:**
```bash
# Opción 1: Usar el script SQL incluido
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -i /backups/restore_sqlserver.sql

# Opción 2: Comando directo
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -Q "RESTORE DATABASE [MiDB] FROM DISK = '/backups/mi_backup.bak' WITH REPLACE"
```

### PostgreSQL
**Crear Backup:**
```bash
# Backup en formato SQL
docker-compose exec postgresql pg_dump -U postgres nombre_db > ./backups/backup_postgresql.sql

# Backup en formato binario
docker-compose exec postgresql pg_dump -U postgres -Fc nombre_db > ./backups/backup_postgresql.dump
```

**Restaurar Backup:**
```bash
# Usar el script incluido
docker-compose exec postgresql bash /backups/restore_postgresql.sh nombre_db backup_postgresql.sql
docker-compose exec postgresql bash /backups/restore_postgresql.sh nombre_db backup_postgresql.dump
```

### MySQL
**Crear Backup:**
```bash
# Backup de una base de datos
docker-compose exec mysql mysqldump -u root -proot123 nombre_db > ./backups/backup_mysql.sql

# Backup de todas las bases de datos
docker-compose exec mysql mysqldump -u root -proot123 --all-databases > ./backups/backup_all_mysql.sql
```

**Restaurar Backup:**
```bash
# Usar el script incluido
docker-compose exec mysql bash /backups/restore_mysql.sh nombre_db backup_mysql.sql
```

### MongoDB
**Crear Backup:**
```bash
# Backup completo de una base de datos
docker-compose exec mongodb mongodump --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db nombre_db --out /backups/

# Backup de una colección específica en JSON
docker-compose exec mongodb mongoexport --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db nombre_db --collection nombre_coleccion --out /backups/backup_coleccion.json --jsonArray
```

**Restaurar Backup:**
```bash
# Restaurar desde directorio de mongodump
docker-compose exec mongodb bash /backups/restore_mongodb.sh nombre_db backup_directory

# Restaurar desde archivo JSON
docker-compose exec mongodb bash /backups/restore_mongodb.sh nombre_db backup_coleccion.json nombre_coleccion
```

### DynamoDB Local
DynamoDB Local no tiene funcionalidad nativa de backup/restore, pero puedes:
1. Usar AWS CLI para exportar/importar datos
2. Usar scripts personalizados para extraer datos via API
3. Los datos persisten en el volumen `dynamodb_data`

## 🔧 Gestión de Automatización

### Verificar Estado de Backups Automáticos
```bash
# Verificar cron jobs y logs de backup en PostgreSQL
docker-compose exec postgresql /scripts/check_cron.sh

# Verificar cron jobs y logs de backup en MySQL
docker-compose exec mysql /scripts/check_cron.sh

# Verificar cron jobs y logs de backup en MongoDB
docker-compose exec mongodb /scripts/check_cron.sh

# Verificar cron jobs y logs de backup en SQL Server
docker-compose exec sqlserver /scripts/check_cron.sh
```

### Ejecutar Backup Manual
```bash
# Ejecutar backup manual en cualquier contenedor
docker-compose exec postgresql /scripts/auto_backup.sh
docker-compose exec mysql /scripts/auto_backup.sh
docker-compose exec mongodb /scripts/auto_backup.sh
docker-compose exec sqlserver /scripts/auto_backup.sh
```

### Ver Logs de Backup
```bash
# Ver logs de backup diario
docker-compose exec postgresql tail -f /var/log/backup/daily.log

# Ver logs de backup semanal
docker-compose exec postgresql tail -f /var/log/backup/weekly.log
```

### Listar Backups Automáticos Generados
```bash
# Ver backups automáticos generados
ls -la ./backups/auto/

# Ver backups automáticos desde dentro del contenedor
docker-compose exec postgresql ls -la /backups/auto/
```

## Comandos Útiles

### Docker Compose
```bash
# Construir e iniciar servicios
docker-compose up -d --build

# Detener servicios
docker-compose down

# Ver logs
docker-compose logs [servicio]

# Reiniciar un servicio específico
docker-compose restart [servicio]

# Reconstruir un servicio específico
docker-compose up -d --build [servicio]
```

### Ver logs de un servicio específico
```bash
docker-compose logs sqlserver
docker-compose logs postgresql
docker-compose logs mongodb
docker-compose logs mysql
docker-compose logs dynamodb
```

### Reiniciar un servicio específico
```bash
docker-compose restart sqlserver
```

### Acceder al shell de un contenedor
```bash
# PostgreSQL
docker-compose exec postgresql psql -U postgres -d postgres

# MySQL
docker-compose exec mysql mysql -u root -p

# MongoDB
docker-compose exec mongodb mongosh -u admin -p admin123
```

### Verificar el estado de DynamoDB Local
```bash
curl http://localhost:8000/
```

## Personalización

Puedes modificar las credenciales y configuraciones editando el archivo `.env` antes de ejecutar `docker-compose up`.

## Volúmenes de Datos

Todos los datos se almacenan en volúmenes Docker nombrados:
- `sqlserver_data`
- `postgresql_data`
- `mongodb_data`
- `mysql_data`
- `dynamodb_data`

Esto garantiza que los datos persistan entre reinicios de contenedores.

## Solución de Problemas

### Puerto ya en uso
Si algún puerto está ocupado, puedes modificar los puertos en el archivo `docker-compose.yml`:
```yaml
ports:
  - "NUEVO_PUERTO:PUERTO_INTERNO"
```

### Problemas de memoria
Si experimentas problemas de rendimiento, asegúrate de tener suficiente RAM asignada a Docker Desktop (recomendado: 4GB+).

### Limpiar todo
Para eliminar todos los contenedores, volúmenes y redes:
```bash
docker-compose down -v
docker system prune -a
```

## ⚠️ Notas Importantes

### 🔒 Seguridad
- **Contraseñas por defecto**: Solo para desarrollo. **CÁMBIALAS EN PRODUCCIÓN**.
- **Acceso de red**: Los servicios están expuestos en todos los interfaces de red.
- **DynamoDB Local**: No requiere credenciales reales de AWS.

### 🔧 Configuración
- **Puertos**: Asegúrate de que los puertos estén disponibles antes de ejecutar.
- **Primera ejecución**: Puede tomar varios minutos debido a la construcción de imágenes personalizadas.
- **Recursos**: Estos servicios pueden consumir recursos significativos. Ajusta según tu sistema.
- **Red Docker**: Todos los servicios están en la misma red Docker para comunicación interna.

### 💾 Gestión de Datos
- **Persistencia**: Los datos se persisten en volúmenes Docker.
- **Eliminación completa**: Para eliminar todos los datos, usa `docker-compose down -v`.
- **Backups automáticos**: Se generan automáticamente en `./backups/auto/`.
- **Restauración automática**: Los backups en `./backups/` se restauran automáticamente al iniciar.

### 🔄 Automatización
- **Backups programados**: Diarios (2:00 AM) y semanales (Domingos 3:00 AM).
- **Limpieza automática**: Solo se mantienen los últimos 7 días de backups.
- **Logs de monitoreo**: Disponibles en `/var/log/backup/` dentro de cada contenedor.
- **Reinicio de contenedores**: La automatización se reconfigura automáticamente.
- **Interfaz web**: Adminer facilita la gestión visual de las bases de datos SQL.

## Contribuciones

Si encuentras algún problema o tienes sugerencias de mejora, no dudes en crear un issue o pull request.