# Guía Rápida de Backups y Restauración

## 📁 Directorio de Backups
Este directorio está montado como `/backups` en todos los contenedores de bases de datos.

## 🚀 Comandos Rápidos

### SQL Server
```bash
# Crear backup
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -Q "BACKUP DATABASE [master] TO DISK = '/backups/master_backup.bak'"

# Restaurar backup
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -Q "RESTORE DATABASE [MiDB] FROM DISK = '/backups/mi_backup.bak' WITH REPLACE"
```

### PostgreSQL
```bash
# Crear backup
docker-compose exec postgresql pg_dump -U postgres postgres > ./backups/postgres_backup.sql

# Restaurar backup
docker-compose exec postgresql bash /backups/restore_postgresql.sh mi_db postgres_backup.sql
```

### MySQL
```bash
# Crear backup
docker-compose exec mysql mysqldump -u root -proot123 testdb > ./backups/mysql_backup.sql

# Restaurar backup
docker-compose exec mysql bash /backups/restore_mysql.sh mi_db mysql_backup.sql
```

### MongoDB
```bash
# Crear backup (directorio)
docker-compose exec mongodb mongodump --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db test --out /backups/

# Crear backup (JSON)
docker-compose exec mongodb mongoexport --host localhost:27017 -u admin -p admin123 --authenticationDatabase admin --db test --collection users --out /backups/users.json --jsonArray

# Restaurar backup
docker-compose exec mongodb bash /backups/restore_mongodb.sh mi_db test
docker-compose exec mongodb bash /backups/restore_mongodb.sh mi_db users.json users
```

## 📋 Scripts Disponibles

- `restore_sqlserver.sql` - Template para restauración de SQL Server
- `restore_postgresql.sh` - Script automático para PostgreSQL
- `restore_mysql.sh` - Script automático para MySQL
- `restore_mongodb.sh` - Script automático para MongoDB

## 💡 Consejos

1. **Coloca tus archivos de backup** en esta carpeta (`./backups/`)
2. **Los scripts son ejecutables** y manejan errores automáticamente
3. **Verifica las credenciales** en los scripts si las has cambiado
4. **Los backups persisten** incluso si reinicias los contenedores
5. **Usa nombres descriptivos** para tus archivos de backup

## 🔧 Personalización

Si has cambiado las credenciales por defecto, edita los scripts con las nuevas credenciales:
- SQL Server: `YourStrong@Passw0rd`
- PostgreSQL: `postgres` / `postgres123`
- MySQL: `root` / `root123`
- MongoDB: `admin` / `admin123`

## ⚠️ Importante

- **Siempre haz backup** antes de restaurar
- **Verifica el espacio disponible** antes de crear backups grandes
- **Los scripts sobrescriben** datos existentes (usan `--drop` o `REPLACE`)
- **Prueba en un entorno de desarrollo** antes de usar en producción