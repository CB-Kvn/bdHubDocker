#!/bin/bash
echo "=== Estado del servicio cron ==="
if command -v apk &> /dev/null; then
    # Alpine Linux
    ps aux | grep crond | grep -v grep || echo "crond no está ejecutándose"
elif command -v service &> /dev/null; then
    # Debian/Ubuntu
    service cron status
elif command -v systemctl &> /dev/null; then
    # Oracle Linux/CentOS
    systemctl status crond
else
    ps aux | grep cron | grep -v grep || echo "No se encontró proceso cron"
fi
echo ""
echo "=== Crontab actual ==="
crontab -l
echo ""
echo "=== Últimos logs de backup ==="
echo "--- Backup diario ---"
tail -10 /var/log/backup/daily.log 2>/dev/null || echo "No hay logs diarios aún"
echo "--- Backup semanal ---"
tail -10 /var/log/backup/weekly.log 2>/dev/null || echo "No hay logs semanales aún"
