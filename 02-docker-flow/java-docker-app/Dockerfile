# =============================================================================
# DOCKERFILE MULTI-ETAPA — java-docker-app
# Charla: Despliegue 101 - Por Andrea Rosero
#
# ¿Qué es un build multi-etapa?
# Un Dockerfile puede tener varias instrucciones FROM. Cada FROM inicia una
# nueva "etapa" con su propia imagen base. La magia está en que podemos
# COPIAR artefactos de una etapa a otra, dejando atrás todo lo que no
# necesitamos en producción (compilador, código fuente, caché de Maven, etc.).
#
# Resultado: la imagen final es mucho más pequeña y segura porque solo
# contiene el JRE (Java Runtime Environment) y el JAR compilado.
# =============================================================================


# =============================================================================
# ETAPA 1: BUILD
# Imagen base: maven:3.9-eclipse-temurin-17
#   - Incluye Maven 3.9 para compilar el proyecto
#   - Incluye el JDK 17 (Eclipse Temurin) para compilar el código Java
#   - Esta imagen pesa ~500 MB, pero NO llegará a la imagen final
# =============================================================================
FROM maven:3.9-eclipse-temurin-17 AS build

# WORKDIR establece el directorio de trabajo dentro del contenedor.
# Todos los comandos RUN, COPY y ADD siguientes operarán desde /app.
# Si el directorio no existe, Docker lo crea automáticamente.
WORKDIR /app

# Copiamos primero el pom.xml por separado para aprovechar el caché de capas
# de Docker. Si el pom.xml no cambia entre builds, Docker reutiliza la capa
# de descarga de dependencias (mvn dependency:go-offline) sin volver a
# descargarlas. Esto acelera significativamente los builds repetidos.
COPY pom.xml .

# Copiamos el código fuente completo al contenedor.
# src/ contiene tanto el código principal (src/main) como los tests (src/test).
COPY src/ src/

# Compilamos el proyecto y generamos el JAR ejecutable.
#
# mvn package: compila, ejecuta tests y empaqueta la aplicación en un JAR.
# -DskipTests: omitimos la ejecución de tests durante el build de Docker.
#
# ¿Por qué saltamos los tests aquí?
# Los tests ya fueron ejecutados y validados por el pipeline de CI
# (GitHub Actions) antes de llegar a esta etapa. Ejecutarlos de nuevo
# dentro del build de Docker solo añadiría tiempo sin aportar valor.
# El pipeline 04-java-docker-evolved-cd.yml valida que el `docker build`
# completo funcione correctamente.
#
# El JAR resultante se genera en: target/java-app-0.0.1-SNAPSHOT.jar
RUN mvn package -DskipTests


# =============================================================================
# ETAPA 2: RUNTIME
# Imagen base: eclipse-temurin:17-jre
#   - Incluye SOLO el JRE 17 (Java Runtime Environment), sin el compilador
#   - Esta imagen pesa ~200 MB, mucho menos que la imagen de build
#   - Principio de mínimo privilegio: en producción no necesitamos Maven
#     ni el JDK completo, solo la capacidad de EJECUTAR el JAR
# =============================================================================
FROM eclipse-temurin:17-jre AS runtime

# Mismo directorio de trabajo que en la etapa de build, por consistencia.
WORKDIR /app

# Copiamos el JAR desde la etapa "build" hacia esta imagen final.
# Sintaxis: COPY --from=<nombre-etapa> <origen> <destino>
#
# Solo copiamos el JAR compilado; el código fuente, las dependencias de Maven
# y el compilador quedan en la etapa "build" y NO se incluyen en esta imagen.
# Esto es la ventaja principal del build multi-etapa.
COPY --from=build /app/target/java-app-0.0.1-SNAPSHOT.jar app.jar

# EXPOSE documenta que el contenedor escucha en el puerto 8080.
# NOTA IMPORTANTE — Puerto 80 vs Puerto 8080:
#   - Puerto 80: convención HTTP tradicional, usado en el flujo sin Docker
#     (ver application.properties en 01-traditional-flow/java-app/).
#     Requiere permisos de root en Linux para puertos < 1024.
#   - Puerto 8080: convención Docker/contenedores. No requiere privilegios
#     especiales y es el estándar de facto para aplicaciones en contenedores.
#   EXPOSE no publica el puerto automáticamente; es documentación para quien
#   ejecute el contenedor. El puerto se publica con `docker run -p 8080:8080`.
EXPOSE 8080

# ENTRYPOINT define el comando que se ejecuta cuando el contenedor arranca.
# Usamos la forma JSON (exec form) en lugar de la forma shell (shell form)
# porque la exec form ejecuta el proceso directamente sin invocar /bin/sh,
# lo que permite que las señales del sistema operativo (como SIGTERM al hacer
# `docker stop`) lleguen directamente al proceso Java y este pueda apagarse
# de forma limpia (graceful shutdown).
ENTRYPOINT ["java", "-jar", "app.jar"]
