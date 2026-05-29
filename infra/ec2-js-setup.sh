#!/bin/bash
# =============================================================================
# ec2-js-setup.sh
# Script de configuración de EC2 para la JS_App (Node.js/Express)
# Charla: Despliegue 101 — Por Andrea Rosero
#
# Uso: sudo bash ec2-js-setup.sh
# Idempotente: puede ejecutarse más de una vez sin causar errores ni duplicar
# configuraciones. Cada sección verifica el estado actual antes de actuar.
# =============================================================================

# Detener el script inmediatamente si cualquier comando falla.
# Esto evita que errores silenciosos dejen la instancia en un estado inconsistente.
set -e

# =============================================================================
# VARIABLES DE CONFIGURACIÓN
# Centralizar las variables aquí facilita adaptar el script a otros proyectos
# o entornos sin tener que buscar valores dispersos en el código.
# =============================================================================
REPO_URL="https://github.com/andreaendigital/aws-despliegue101.git"
APP_DIR="/opt/aws-despliegue101"
SERVICE_NAME="js-app"

echo "============================================================"
echo " Configurando EC2 para JS_App — Charla: Despliegue 101"
echo "============================================================"

# =============================================================================
# SECCIÓN 1: Actualizar paquetes del sistema
# Es una buena práctica actualizar el índice de paquetes antes de instalar
# cualquier software para asegurarse de obtener las versiones más recientes
# y evitar conflictos de dependencias.
# =============================================================================
echo ""
echo "[1/6] Actualizando paquetes del sistema..."

if command -v apt-get &> /dev/null; then
    # Distribuciones basadas en Debian/Ubuntu (ej. Ubuntu 22.04 en EC2)
    apt-get update -y
    apt-get install -y curl git
elif command -v yum &> /dev/null; then
    # Distribuciones basadas en Red Hat (ej. Amazon Linux 2)
    yum update -y
    yum install -y curl git
else
    echo "ERROR: No se encontró apt-get ni yum. Distribución no soportada." >&2
    exit 1
fi

echo "✓ Paquetes del sistema actualizados."

# =============================================================================
# SECCIÓN 2: Instalar Node.js
# Se verifica primero si Node.js ya está instalado para garantizar idempotencia.
# Si no está instalado, se usa el script oficial de NodeSource para instalar
# Node.js 20 LTS, que es la versión usada en los pipelines de CI.
# =============================================================================
echo ""
echo "[2/6] Verificando instalación de Node.js..."

if command -v node &> /dev/null; then
    # Node.js ya está instalado; no se hace nada para evitar sobrescribir
    # una instalación existente que podría tener configuraciones personalizadas.
    NODE_VERSION=$(node --version)
    echo "✓ Node.js ya está instalado: ${NODE_VERSION}. Se omite la instalación."
else
    echo "  Node.js no encontrado. Instalando Node.js 20 LTS via NodeSource..."

    if command -v apt-get &> /dev/null; then
        # Instalar Node.js 20 LTS en Ubuntu/Debian usando el script de NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    elif command -v yum &> /dev/null; then
        # Instalar Node.js 20 LTS en Amazon Linux / CentOS usando NodeSource
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        yum install -y nodejs
    fi

    echo "✓ Node.js instalado: $(node --version)"
fi

# =============================================================================
# SECCIÓN 3: Clonar o actualizar el repositorio
# Se verifica si el directorio de la aplicación ya existe:
# - Si NO existe: se clona el repositorio desde GitHub.
# - Si SÍ existe: se hace git pull para obtener los últimos cambios.
# Esto garantiza que el script sea idempotente y que siempre tengamos
# el código más reciente sin necesidad de borrar y volver a clonar.
# =============================================================================
echo ""
echo "[3/6] Clonando o actualizando el repositorio..."

if [ -d "$APP_DIR" ]; then
    # El directorio ya existe; actualizamos el código con git pull
    echo "  El directorio ${APP_DIR} ya existe. Ejecutando git pull..."
    git -C "$APP_DIR" pull
    echo "✓ Repositorio actualizado en ${APP_DIR}."
else
    # El directorio no existe; clonamos el repositorio por primera vez
    echo "  Clonando repositorio desde ${REPO_URL}..."
    git clone "$REPO_URL" "$APP_DIR"
    echo "✓ Repositorio clonado en ${APP_DIR}."
fi

# =============================================================================
# SECCIÓN 4: Instalar dependencias de la aplicación
# Se ejecuta npm install en la carpeta de la JS_App para instalar Express
# y las demás dependencias definidas en package.json.
# El flag --prefix permite ejecutar npm desde cualquier directorio.
# =============================================================================
echo ""
echo "[4/6] Instalando dependencias de la JS_App..."

npm install --prefix "${APP_DIR}/01-traditional-flow/javascript-app"

echo "✓ Dependencias instaladas."

# =============================================================================
# SECCIÓN 5: Crear el unit file de systemd
# systemd es el sistema de init de Linux que gestiona servicios del sistema.
# Configurar la JS_App como servicio systemd permite que:
# - La aplicación arranque automáticamente al iniciar la instancia EC2.
# - Se reinicie automáticamente si falla (Restart=on-failure).
# - Sus logs sean accesibles con journalctl.
#
# Se verifica con systemctl is-enabled si el servicio ya existe para
# garantizar idempotencia y evitar sobrescribir configuraciones manuales.
# =============================================================================
echo ""
echo "[5/6] Configurando el servicio systemd..."

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Verificar si el servicio ya está habilitado en systemd
if systemctl is-enabled "$SERVICE_NAME" &> /dev/null; then
    echo "  El servicio ${SERVICE_NAME} ya está registrado en systemd. Se omite la creación del unit file."
else
    echo "  Creando unit file en ${SERVICE_FILE}..."

    # Crear el unit file de systemd para la JS_App.
    # ExecStart apunta directamente a node src/server.js usando la ruta absoluta
    # al ejecutable de node para evitar problemas con el PATH en el contexto de systemd.
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=JS_App — Charla Despliegue 101 (Node.js/Express)
Documentation=https://github.com/andreaendigital/aws-despliegue101
After=network.target

[Service]
# Usuario www-data para ejecutar la aplicación (usuario estándar de servidores web en Ubuntu)
User=www-data

# Directorio de trabajo de la aplicación
WorkingDirectory=${APP_DIR}/01-traditional-flow/javascript-app

# Comando para iniciar la aplicación
# Se usa la ruta absoluta a node para garantizar que systemd encuentre el ejecutable
ExecStart=$(command -v node) src/server.js

# Reiniciar siempre el servicio si se detiene, sin importar la causa
Restart=always
RestartSec=5

# Variables de entorno: la app escucha en el puerto 80
Environment=PORT=80
Environment=NODE_ENV=production

# Redirigir stdout y stderr al journal de systemd para facilitar el debugging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
# Iniciar el servicio cuando el sistema alcance el modo multi-usuario (arranque normal)
WantedBy=multi-user.target
EOF

    echo "✓ Unit file creado en ${SERVICE_FILE}."
fi

# =============================================================================
# SECCIÓN 6: Habilitar e iniciar el servicio
# - daemon-reload: recarga la configuración de systemd para que reconozca
#   el nuevo unit file (o los cambios en uno existente).
# - enable: configura el servicio para que arranque automáticamente al iniciar
#   la instancia EC2.
# - restart: inicia el servicio (o lo reinicia si ya estaba corriendo) para
#   aplicar cualquier cambio de código obtenido en el git pull.
# =============================================================================
echo ""
echo "[6/6] Habilitando e iniciando el servicio ${SERVICE_NAME}..."

# Recargar la configuración de systemd para reconocer el unit file
systemctl daemon-reload

# Habilitar el servicio para que arranque automáticamente con la instancia
systemctl enable "$SERVICE_NAME"

# Reiniciar el servicio para aplicar el código más reciente
# (restart funciona tanto si el servicio estaba detenido como si estaba corriendo)
systemctl restart "$SERVICE_NAME"

echo "✓ Servicio ${SERVICE_NAME} habilitado e iniciado."

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo ""
echo "============================================================"
echo " ✅ Configuración completada exitosamente."
echo ""
echo " Servicio: ${SERVICE_NAME}"
echo " Directorio: ${APP_DIR}/01-traditional-flow/javascript-app"
echo " Puerto: 80"
echo ""
echo " Comandos útiles:"
echo "   Ver estado:  systemctl status ${SERVICE_NAME}"
echo "   Ver logs:    journalctl -u ${SERVICE_NAME} -f"
echo "   Reiniciar:   systemctl restart ${SERVICE_NAME}"
echo "   Detener:     systemctl stop ${SERVICE_NAME}"
echo "============================================================"
