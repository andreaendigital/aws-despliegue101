#!/bin/bash
# =============================================================================
# ec2-java-setup.sh
# Script de configuración de EC2 para la Java_App (Spring Boot)
# Charla: Despliegue 101 — Por Andrea Rosero
#
# Uso: sudo bash ec2-java-setup.sh
# Idempotente: puede ejecutarse más de una vez sin causar errores.
# =============================================================================

set -e

# =============================================================================
# VARIABLES
# =============================================================================
REPO_URL="https://github.com/andreaendigital/aws-despliegue101.git"
APP_DIR="/opt/aws-despliegue101"
SERVICE_NAME="java-app"

echo "============================================================"
echo " Configurando EC2 para Java_App — Charla: Despliegue 101"
echo "============================================================"

# =============================================================================
# 1. Actualizar paquetes del sistema
# =============================================================================
echo ""
echo "[1/7] Actualizando paquetes del sistema..."
apt-get update -y
apt-get install -y curl git

echo "✓ Paquetes actualizados."

# =============================================================================
# 2. Instalar Java 17
# =============================================================================
echo ""
echo "[2/7] Verificando instalación de Java 17..."

if command -v java &> /dev/null; then
    echo "✓ Java ya instalado: $(java -version 2>&1 | head -1). Se omite."
else
    echo "  Instalando Java 17..."
    apt-get install -y openjdk-17-jdk
    echo "✓ Java instalado: $(java -version 2>&1 | head -1)"
fi

# =============================================================================
# 3. Instalar Maven
# =============================================================================
echo ""
echo "[3/7] Verificando instalación de Maven..."

if command -v mvn &> /dev/null; then
    echo "✓ Maven ya instalado. Se omite."
else
    echo "  Instalando Maven..."
    apt-get install -y maven
    echo "✓ Maven instalado."
fi

# =============================================================================
# 4. Instalar nginx
# =============================================================================
echo ""
echo "[4/7] Verificando instalación de nginx..."

if command -v nginx &> /dev/null; then
    echo "✓ nginx ya instalado. Se omite."
else
    echo "  Instalando nginx..."
    apt-get install -y nginx
    echo "✓ nginx instalado."
fi

# =============================================================================
# 5. Clonar o actualizar el repositorio
# =============================================================================
echo ""
echo "[5/7] Clonando o actualizando el repositorio..."

if [ -d "$APP_DIR" ]; then
    echo "  Repositorio existe. Ejecutando git pull..."
    git -C "$APP_DIR" pull
    echo "✓ Repositorio actualizado."
else
    echo "  Clonando desde ${REPO_URL}..."
    git clone "$REPO_URL" "$APP_DIR"
    echo "✓ Repositorio clonado en ${APP_DIR}."
fi

# CI/CD también depende de permisos UNIX correctos.
# El pipeline de GitHub Actions se conecta como usuario 'ubuntu' via SSH/SCP
# para copiar el .jar compilado al servidor. Si 'ubuntu' no es dueño del
# directorio de despliegue, el SCP fallará con "Permission denied".
# Esta línea hace que ubuntu sea dueño de todo el árbol de directorios.
sudo chown -R ubuntu:ubuntu "${APP_DIR}"
echo "✓ Permisos asignados a ubuntu en ${APP_DIR}."

# =============================================================================
# 6. Configurar el servicio systemd
# =============================================================================
echo ""
echo "[6/7] Configurando servicio systemd '${SERVICE_NAME}'..."

# Copiar el unit file versionado desde el repositorio
sudo cp "${APP_DIR}/infra/java-app.service" /etc/systemd/system/java-app.service

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"

echo "✓ Servicio systemd configurado."

# =============================================================================
# 7. Configurar nginx como proxy inverso
# =============================================================================
echo ""
echo "[7/7] Configurando nginx como proxy inverso..."

sudo cp "${APP_DIR}/infra/nginx-java-app.conf" /etc/nginx/sites-available/java-app
sudo ln -sf /etc/nginx/sites-available/java-app /etc/nginx/sites-enabled/java-app
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

echo "✓ nginx configurado."

# =============================================================================
# RESUMEN
# =============================================================================
echo ""
echo "============================================================"
echo " ✅ Configuración completada."
echo ""
echo " Próximos pasos:"
echo "   1. Compilar la app: mvn -f ${APP_DIR}/01-traditional-flow/java-app/pom.xml clean package -DskipTests"
echo "   2. Iniciar servicio: sudo systemctl start java-app"
echo "   3. Ver logs:         journalctl -u java-app -f"
echo "============================================================"
