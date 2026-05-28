#!/bin/bash
# =============================================================================
# ec2-python-setup.sh
# Script de configuración de EC2 para la Python_App (Flask)
# Charla: Despliegue 101 - Por Andrea Rosero
#
# Uso: sudo bash ec2-python-setup.sh
# Idempotente: puede ejecutarse múltiples veces sin efectos secundarios.
# =============================================================================

set -e  # Detener el script ante cualquier error

# -----------------------------------------------------------------------------
# Variables de configuración
# Ajusta REPO_URL con la URL real de tu repositorio en GitHub.
# -----------------------------------------------------------------------------
REPO_URL="https://github.com/andrearosero/aws-despliegue101.git"
APP_DIR="/opt/aws-despliegue101"
SERVICE_NAME="python-app"

echo "==> Iniciando configuración de la Python_App en EC2..."

# -----------------------------------------------------------------------------
# 1. Actualizar paquetes del sistema
# -----------------------------------------------------------------------------
echo "==> [1/5] Actualizando paquetes del sistema..."
apt-get update -y

# -----------------------------------------------------------------------------
# 2. Instalar Python 3 y pip (solo si no están instalados)
# -----------------------------------------------------------------------------
echo "==> [2/5] Verificando e instalando Python 3 y pip..."

if command -v python3 &>/dev/null; then
    echo "    Python 3 ya está instalado: $(python3 --version)"
else
    echo "    Python 3 no encontrado. Instalando..."
    apt-get install -y python3
fi

if command -v pip3 &>/dev/null; then
    echo "    pip3 ya está instalado: $(pip3 --version)"
else
    echo "    pip3 no encontrado. Instalando..."
    apt-get install -y python3-pip
fi

# -----------------------------------------------------------------------------
# 3. Clonar el repositorio o actualizar si ya existe
# -----------------------------------------------------------------------------
echo "==> [3/5] Configurando el repositorio en ${APP_DIR}..."

if [ -d "${APP_DIR}/.git" ]; then
    echo "    El repositorio ya existe. Actualizando con git pull..."
    git -C "${APP_DIR}" pull
else
    echo "    Clonando el repositorio desde ${REPO_URL}..."
    git clone "${REPO_URL}" "${APP_DIR}"
fi

# -----------------------------------------------------------------------------
# 4. Instalar dependencias de Python
# -----------------------------------------------------------------------------
echo "==> [4/5] Instalando dependencias de Python..."
pip3 install -r "${APP_DIR}/01-traditional-flow/python-app/requirements.txt"

# -----------------------------------------------------------------------------
# 5. Crear el archivo de unidad systemd (idempotente)
# El servicio ejecuta app.py desde el directorio src/ de la python-app.
# -----------------------------------------------------------------------------
echo "==> [5/5] Configurando el servicio systemd '${SERVICE_NAME}'..."

WORKING_DIR="${APP_DIR}/01-traditional-flow/python-app/src"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Escribir (o sobreescribir) el archivo de unidad — operación idempotente
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Python App - Charla Despliegue 101
After=network.target

[Service]
# Directorio de trabajo: carpeta src/ de la python-app
WorkingDirectory=${WORKING_DIR}
# Comando de inicio de la aplicación Flask
ExecStart=/usr/bin/python3 ${WORKING_DIR}/app.py
# Reiniciar automáticamente si el proceso falla
Restart=always
RestartSec=5
# Usuario sin privilegios para mayor seguridad
User=www-data
# Variable de entorno: puerto en el que escucha Flask
Environment=PORT=80

[Install]
WantedBy=multi-user.target
EOF

echo "    Archivo de unidad creado en ${SERVICE_FILE}"

# Recargar systemd para que reconozca el nuevo/actualizado archivo de unidad
systemctl daemon-reload

# Habilitar el servicio para que arranque automáticamente al reiniciar la instancia
systemctl enable "${SERVICE_NAME}"

# Iniciar (o reiniciar) el servicio
systemctl restart "${SERVICE_NAME}"

echo ""
echo "==> ¡Configuración completada exitosamente!"
echo "    Servicio '${SERVICE_NAME}' habilitado e iniciado."
echo "    Verifica el estado con: sudo systemctl status ${SERVICE_NAME}"
echo "    Consulta los logs con:  sudo journalctl -u ${SERVICE_NAME} -f"
