#!/bin/bash

# Script para configurar cron jobs para backups automáticos
# Se ejecuta al inicializar los contenedores

echo "[CRON] Configurando cron jobs para backups automáticos..."

# Detectar distribución e instalar cron si no está disponible
if ! command -v cron &> /dev/null && ! command -v crond &> /dev/null; then
    echo "[CRON] Instalando cron..."
    if command -v apk &> /dev/null; then
        # Alpine Linux
        echo "[CRON] Detectado Alpine Linux"
        apk add --no-cache dcron
    elif command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        echo "[CRON] Detectado Debian/Ubuntu"
        apt-get update && apt-get install -y cron
    elif command -v microdnf &> /dev/null; then
        # Oracle Linux (MySQL)
        echo "[CRON] Detectado Oracle Linux"
        microdnf install -y cronie
    else
        echo "[CRON] ⚠️  No se pudo detectar el gestor de paquetes"
    fi
fi

# Crear directorio para logs de cron
mkdir -p /var/log/backup

# Configurar cron job para backup diario a las 2:00 AM
echo "[CRON] Configurando backup diario a las 2:00 AM..."
echo "0 2 * * * /scripts/auto_backup.sh >> /var/log/backup/daily.log 2>&1" > /tmp/crontab_backup

# Configurar cron job para backup semanal los domingos a las 3:00 AM
echo "[CRON] Configurando backup semanal los domingos a las 3:00 AM..."
echo "0 3 * * 0 /scripts/auto_backup.sh >> /var/log/backup/weekly.log 2>&1" >> /tmp/crontab_backup

# Instalar el crontab
crontab /tmp/crontab_backup

# Verificar que el crontab se instaló correctamente
echo "[CRON] Crontab instalado:"
crontab -l

# Iniciar el servicio cron según la distribución
echo "[CRON] Iniciando servicio cron..."
if command -v apk &> /dev/null; then
    # Alpine Linux usa crond
    crond -b
    echo "[CRON] Servicio crond iniciado en Alpine Linux"
elif command -v service &> /dev/null; then
    # Debian/Ubuntu
    service cron start
    if command -v update-rc.d &> /dev/null; then
        update-rc.d cron enable
    fi
    echo "[CRON] Servicio cron iniciado en Debian/Ubuntu"
elif command -v systemctl &> /dev/null; then
    # Oracle Linux/CentOS
    systemctl start crond
    systemctl enable crond
    echo "[CRON] Servicio crond iniciado en Oracle Linux"
else
    echo "[CRON] ⚠️  No se pudo iniciar el servicio cron automáticamente"
fi

echo "[CRON] Configuración de cron completada"
echo "[CRON] Logs de backup se guardarán en:"
echo "  - Diario: /var/log/backup/daily.log"
echo "  - Semanal: /var/log/backup/weekly.log"

# Crear script para verificar el estado de cron
cat > /scripts/check_cron.sh << 'EOF'
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
EOF

chmod +x /scripts/check_cron.sh

echo "[CRON] Script de verificación creado: /scripts/check_cron.sh"