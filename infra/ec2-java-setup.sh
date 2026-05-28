#!/bin/bash
# =============================================================================
# ec2-java-setup.sh
# Script de configuración de EC2 para la Java_App (Spring Boot)
# Charla: Despliegue 101 — Por Andrea Rosero
#
# Uso: sudo bash ec2-java-setup.sh
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
REPO_URL="https://github.com/andrearosero/aws-despliegue101.git"
APP_DIR="/opt/aws-despliegue101"
SERVICE_NAME="java-app"
# JAR_PATH se define en la Sección 5 tras compilar el proyecto con Maven
JAR_PATH=""

echo "============================================================"
echo " Configurando EC2 para Java_App — Charla: Despliegue 101"
echo "============================================================"

# =============================================================================
# SECCIÓN 1: Actualizar paquetes del sistema
# Es una buena práctica actualizar el índice de paquetes antes de instalar
# cualquier software para asegurarse de obtener las versiones más recientes
# y evitar conflictos de dependencias.
# =============================================================================
echo ""
echo "[1/7] Actualizando paquetes del sistema..."

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
# SECCIÓN 2: Instalar Java 17
# Se verifica primero si Java ya está instalado para garantizar idempotencia.
# Si no está instalado, se usa Eclipse Adoptium (Temurin) en Ubuntu/Debian
# o Amazon Corretto en Amazon Linux / CentOS.
# Java 17 es la versión LTS usada en los pipelines de CI del proyecto.
# =============================================================================
echo ""
echo "[2/7] Verificando instalación de Java 17..."

if command -v java &> /dev/null; then
    # Java ya está instalado; no se hace nada para evitar sobrescribir
    # una instalación existente que podría tener configuraciones personalizadas.
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    echo "✓ Java ya está instalado: ${JAVA_VERSION}. Se omite la instalación."
else
    echo "  Java no encontrado. Instalando Java 17..."

    if command -v apt-get &> /dev/null; then
        # Instalar Temurin 17 (Eclipse Adoptium) en Ubuntu/Debian.
        # Temurin es la distribución OpenJDK de referencia, gratuita y con soporte LTS.
        echo "  Configurando repositorio de Eclipse Adoptium..."
        apt-get install -y wget apt-transport-https gnupg

        # Agregar la clave GPG del repositorio de Adoptium
        wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
            | gpg --dearmor \
            | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null

        # Agregar el repositorio de Adoptium para la versión actual de Ubuntu
        echo "deb https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
            | tee /etc/apt/sources.list.d/adoptium.list

        apt-get update -y
        apt-get install -y temurin-17-jdk

    elif command -v yum &> /dev/null; then
        # Instalar Amazon Corretto 17 en Amazon Linux / CentOS.
        # Corretto es la distribución OpenJDK de Amazon, optimizada para AWS.
        yum install -y java-17-amazon-corretto
    fi

    echo "✓ Java instalado: $(java -version 2>&1 | head -1)"
fi

# =============================================================================
# SECCIÓN 3: Instalar Maven
# Maven es la herramienta de construcción del proyecto Java.
# Se verifica primero si ya está instalado para garantizar idempotencia.
# Maven compilará el proyecto y generará el JAR ejecutable.
# =============================================================================
echo ""
echo "[3/7] Verificando instalación de Maven..."

if command -v mvn &> /dev/null; then
    # Maven ya está instalado; no se hace nada
    MVN_VERSION=$(mvn --version | head -1)
    echo "✓ Maven ya está instalado: ${MVN_VERSION}. Se omite la instalación."
else
    echo "  Maven no encontrado. Instalando Maven..."

    if command -v apt-get &> /dev/null; then
        # Instalar Maven desde los repositorios oficiales de Ubuntu/Debian
        apt-get install -y maven
    elif command -v yum &> /dev/null; then
        # Instalar Maven desde los repositorios de Amazon Linux / CentOS
        yum install -y maven
    fi

    echo "✓ Maven instalado: $(mvn --version | head -1)"
fi

# =============================================================================
# SECCIÓN 4: Clonar o actualizar el repositorio
# Se verifica si el directorio de la aplicación ya existe:
# - Si NO existe: se clona el repositorio desde GitHub.
# - Si SÍ existe: se hace git pull para obtener los últimos cambios.
# Esto garantiza que el script sea idempotente y que siempre tengamos
# el código más reciente sin necesidad de borrar y volver a clonar.
# =============================================================================
echo ""
echo "[4/7] Clonando o actualizando el repositorio..."

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
# SECCIÓN 5: Compilar el proyecto y generar el JAR
# Maven compila el código fuente Java y empaqueta la aplicación en un JAR
# ejecutable (fat JAR / uber JAR) que incluye todas las dependencias.
# El flag -DskipTests omite las pruebas durante el despliegue para acelerar
# el proceso; las pruebas ya fueron validadas en el pipeline de CI.
# =============================================================================
echo ""
echo "[5/7] Compilando la Java_App con Maven..."

mvn -f "${APP_DIR}/01-traditional-flow/java-app/pom.xml" clean package -DskipTests

# Localizar el JAR generado en la carpeta target/
# Spring Boot genera un JAR con el sufijo del nombre del artefacto definido en pom.xml
JAR_PATH=$(find "${APP_DIR}/01-traditional-flow/java-app/target" -name "*.jar" ! -name "*sources*" | head -1)

if [ -z "$JAR_PATH" ]; then
    echo "ERROR: No se encontró el JAR generado en target/. Verifica que Maven compiló correctamente." >&2
    exit 1
fi

echo "✓ JAR generado en: ${JAR_PATH}"

# =============================================================================
# SECCIÓN 6: Crear el unit file de systemd
# systemd es el sistema de init de Linux que gestiona servicios del sistema.
# Configurar la Java_App como servicio systemd permite que:
# - La aplicación arranque automáticamente al iniciar la instancia EC2.
# - Se reinicie automáticamente si falla (Restart=always).
# - Sus logs sean accesibles con journalctl.
#
# Se verifica con systemctl is-enabled si el servicio ya existe para
# garantizar idempotencia y evitar sobrescribir configuraciones manuales.
# =============================================================================
echo ""
echo "[6/7] Configurando el servicio systemd..."

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Verificar si el servicio ya está habilitado en systemd
if systemctl is-enabled "$SERVICE_NAME" &> /dev/null; then
    echo "  El servicio ${SERVICE_NAME} ya está registrado en systemd. Se omite la creación del unit file."
else
    echo "  Creando unit file en ${SERVICE_FILE}..."

    # Crear el unit file de systemd para la Java_App.
    # ExecStart ejecuta el JAR directamente con java -jar usando la ruta absoluta
    # al ejecutable de java para evitar problemas con el PATH en el contexto de systemd.
    # SERVER_PORT=80 permite que Spring Boot escuche en el puerto 80 sin modificar
    # application.properties, siguiendo la convención de configuración por entorno.
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Java_App — Charla Despliegue 101 (Spring Boot)
Documentation=https://github.com/andrearosero/aws-despliegue101
After=network.target

[Service]
# Usuario www-data para ejecutar la aplicación (usuario estándar de servidores web en Ubuntu)
User=www-data

# Directorio de trabajo de la aplicación Java
WorkingDirectory=${APP_DIR}/01-traditional-flow/java-app

# Comando para iniciar la aplicación Spring Boot
# Se usa la ruta absoluta a java para garantizar que systemd encuentre el ejecutable
ExecStart=$(command -v java) -jar ${JAR_PATH}

# Reiniciar siempre el servicio si se detiene, sin importar la causa
Restart=always
RestartSec=5

# Variables de entorno: Spring Boot lee SERVER_PORT para determinar el puerto de escucha
Environment=SERVER_PORT=80

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
# SECCIÓN 7: Habilitar e iniciar el servicio
# - daemon-reload: recarga la configuración de systemd para que reconozca
#   el nuevo unit file (o los cambios en uno existente).
# - enable: configura el servicio para que arranque automáticamente al iniciar
#   la instancia EC2.
# - restart: inicia el servicio (o lo reinicia si ya estaba corriendo) para
#   aplicar cualquier cambio de código obtenido en el git pull.
# =============================================================================
echo ""
echo "[7/7] Habilitando e iniciando el servicio ${SERVICE_NAME}..."

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
echo " Directorio: ${APP_DIR}/01-traditional-flow/java-app"
echo " JAR: ${JAR_PATH}"
echo " Puerto: 80"
echo ""
echo " Comandos útiles:"
echo "   Ver estado:  systemctl status ${SERVICE_NAME}"
echo "   Ver logs:    journalctl -u ${SERVICE_NAME} -f"
echo "   Reiniciar:   systemctl restart ${SERVICE_NAME}"
echo "   Detener:     systemctl stop ${SERVICE_NAME}"
echo "============================================================"
