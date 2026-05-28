#!/bin/bash
# =============================================================================
# ec2-docker-setup.sh
# Charla: Despliegue 101 - Por Andrea Rosero
#
# Propósito: Configurar una instancia EC2 (Ubuntu) para ejecutar la
# Java_Docker_App como contenedor Docker.
#
# Uso:
#   chmod +x ec2-docker-setup.sh
#   sudo ./ec2-docker-setup.sh
#
# Idempotente: puede ejecutarse múltiples veces sin duplicar configuraciones.
# =============================================================================

# set -e hace que el script se detenga inmediatamente si cualquier comando
# retorna un código de salida distinto de 0. Esto evita que errores silenciosos
# pasen desapercibidos y dejen el sistema en un estado inconsistente.
set -e

# =============================================================================
# VARIABLES DE CONFIGURACIÓN
# Centralizar las variables aquí facilita adaptar el script a otros proyectos
# sin tener que buscar valores dispersos a lo largo del archivo.
# =============================================================================
REPO_URL="https://github.com/andrearosero/aws-despliegue101.git"
APP_DIR="/opt/aws-despliegue101"
IMAGE_NAME="java-docker-app"
CONTAINER_NAME="java-docker-app"

echo "============================================================"
echo "  Despliegue 101 — Configuración EC2 con Docker"
echo "  Por Andrea Rosero"
echo "============================================================"

# =============================================================================
# SECCIÓN 1: ACTUALIZACIÓN DE PAQUETES DEL SISTEMA
# Antes de instalar cualquier software, actualizamos el índice de paquetes
# para asegurarnos de obtener las versiones más recientes disponibles.
# =============================================================================
echo ""
echo "[1/6] Actualizando paquetes del sistema..."
apt-get update -y

# =============================================================================
# SECCIÓN 2: INSTALACIÓN DE DOCKER
# Verificamos si Docker ya está instalado antes de intentar instalarlo.
# Esto hace el script idempotente: si Docker ya existe, no lo reinstalamos.
#
# `command -v docker` retorna la ruta del binario si existe, o falla si no.
# La redirección a /dev/null suprime la salida para mantener los logs limpios.
# =============================================================================
echo ""
echo "[2/6] Verificando e instalando Docker..."

if command -v docker > /dev/null 2>&1; then
    echo "  Docker ya está instalado: $(docker --version)"
    echo "  Omitiendo instalación."
else
    echo "  Docker no encontrado. Instalando docker.io..."
    apt-get install -y docker.io
    echo "  Docker instalado correctamente: $(docker --version)"
fi

# =============================================================================
# SECCIÓN 3: HABILITACIÓN E INICIO DEL SERVICIO DOCKER
# Habilitamos Docker para que arranque automáticamente con el sistema
# (systemctl enable) y lo iniciamos si no está corriendo (systemctl start).
# Ambos comandos son idempotentes: no fallan si Docker ya está activo.
# =============================================================================
echo ""
echo "[3/6] Habilitando e iniciando el servicio Docker..."
systemctl enable docker
systemctl start docker
echo "  Servicio Docker activo: $(systemctl is-active docker)"

# =============================================================================
# SECCIÓN 4: CLONAR O ACTUALIZAR EL REPOSITORIO
# Verificamos si el directorio del repositorio ya existe:
#   - Si NO existe: clonamos el repositorio desde GitHub.
#   - Si SÍ existe: hacemos git pull para obtener los últimos cambios.
# Esto garantiza que siempre tengamos el código más reciente sin duplicar
# el repositorio si el script se ejecuta más de una vez.
# =============================================================================
echo ""
echo "[4/6] Clonando o actualizando el repositorio..."

if [ -d "$APP_DIR" ]; then
    echo "  El directorio $APP_DIR ya existe. Actualizando con git pull..."
    git -C "$APP_DIR" pull
    echo "  Repositorio actualizado."
else
    echo "  Clonando repositorio desde $REPO_URL..."
    git clone "$REPO_URL" "$APP_DIR"
    echo "  Repositorio clonado en $APP_DIR."
fi

# =============================================================================
# SECCIÓN 5: CONSTRUCCIÓN DE LA IMAGEN DOCKER
# Construimos la imagen Docker a partir del Dockerfile multi-etapa ubicado en
# 02-docker-flow/java-docker-app/. El Dockerfile compila el proyecto con Maven
# y genera una imagen final ligera basada en eclipse-temurin:17-jre.
#
# La opción --no-cache asegura que siempre se use el código más reciente
# del repositorio, evitando que Docker reutilice capas de builds anteriores
# con código desactualizado.
# =============================================================================
echo ""
echo "[5/6] Construyendo la imagen Docker '$IMAGE_NAME'..."
docker build \
    --no-cache \
    -t "$IMAGE_NAME" \
    "$APP_DIR/02-docker-flow/java-docker-app"
echo "  Imagen '$IMAGE_NAME' construida exitosamente."

# =============================================================================
# SECCIÓN 6: DETENER, ELIMINAR Y VOLVER A EJECUTAR EL CONTENEDOR
# Para garantizar idempotencia, primero detenemos y eliminamos cualquier
# contenedor previo con el mismo nombre antes de crear uno nuevo.
#
# El operador `|| true` evita que el script falle si el contenedor no existe
# (por ejemplo, en la primera ejecución). Esto es equivalente a "intentar
# detener/eliminar, pero no fallar si no hay nada que detener/eliminar".
#
# Opciones de `docker run`:
#   -d                    : modo detached (en segundo plano)
#   --name                : nombre del contenedor para identificarlo fácilmente
#   -p 80:8080            : mapea el puerto 80 del host al 8080 del contenedor
#                           (la app escucha en 8080 dentro del contenedor,
#                            pero es accesible en el puerto 80 del servidor)
#   --restart unless-stopped : reinicia el contenedor automáticamente si falla
#                              o si el servidor se reinicia, a menos que se
#                              haya detenido manualmente con `docker stop`
# =============================================================================
echo ""
echo "[6/6] Desplegando el contenedor '$CONTAINER_NAME'..."

echo "  Deteniendo contenedor existente (si aplica)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true

echo "  Eliminando contenedor existente (si aplica)..."
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "  Iniciando nuevo contenedor..."
docker run \
    -d \
    --name "$CONTAINER_NAME" \
    -p 80:8080 \
    --restart unless-stopped \
    "$IMAGE_NAME"

echo "  Contenedor '$CONTAINER_NAME' iniciado correctamente."

# =============================================================================
# RESUMEN FINAL
# Mostramos información útil para verificar que el despliegue fue exitoso.
# =============================================================================
echo ""
echo "============================================================"
echo "  ¡Despliegue completado exitosamente!"
echo "============================================================"
echo ""
echo "  Contenedor en ejecución:"
docker ps --filter "name=$CONTAINER_NAME" --format "  ID: {{.ID}} | Estado: {{.Status}} | Puertos: {{.Ports}}"
echo ""
echo "  La aplicación está disponible en:"
echo "    http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo '<IP-PUBLICA-EC2>')/"
echo ""
echo "  Para verificar el estado de salud:"
echo "    curl http://localhost/health"
echo ""
echo "  Para ver los logs del contenedor:"
echo "    docker logs $CONTAINER_NAME"
echo "============================================================"
