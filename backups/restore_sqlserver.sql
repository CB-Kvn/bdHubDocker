-- Script de restauración para SQL Server
-- Uso: Ejecutar desde SQL Server Management Studio o sqlcmd
-- Asegúrate de que el archivo .bak esté en la carpeta /backups dentro del contenedor

-- Ejemplo de restauración de base de datos
-- Reemplaza 'NombreBaseDatos' y 'archivo_backup.bak' con tus valores

USE master;
GO

-- Verificar archivos de backup disponibles
-- RESTORE FILELISTONLY FROM DISK = '/backups/archivo_backup.bak';

-- Restaurar base de datos (ejemplo)
/*
RESTORE DATABASE [NombreBaseDatos] 
FROM DISK = '/backups/archivo_backup.bak'
WITH 
    MOVE 'NombreBaseDatos' TO '/var/opt/mssql/data/NombreBaseDatos.mdf',
    MOVE 'NombreBaseDatos_Log' TO '/var/opt/mssql/data/NombreBaseDatos_Log.ldf',
    REPLACE,
    RECOVERY;
GO
*/

-- Comando para ejecutar desde terminal (alternativa)
-- docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Passw0rd' -i /backups/restore_sqlserver.sql

-- Para restaurar un backup específico, usa este template:
/*
RESTORE DATABASE [MiBaseDatos] 
FROM DISK = '/backups/mi_backup.bak'
WITH REPLACE, RECOVERY;
GO
*/

PRINT 'Script de restauración SQL Server cargado. Modifica y ejecuta los comandos según tus necesidades.';