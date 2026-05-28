# Implementation Plan: aws-despliegue101

## Overview

Implementación incremental del repositorio educativo "Despliegue 101". Las tareas siguen el orden natural de dependencias: primero la estructura base y los archivos compartidos, luego cada aplicación con sus pruebas, después los pipelines de CI, y finalmente los scripts de infraestructura EC2 y el README.

No se aplican property-based tests porque el diseño lo excluye explícitamente: los endpoints retornan respuestas fijas y el repositorio es principalmente configuración/IaC.

## Tasks

- [x] 1. Crear la estructura de carpetas del repositorio
  - Crear los directorios: `01-traditional-flow/javascript-app/src/public/`, `01-traditional-flow/javascript-app/test/`, `01-traditional-flow/python-app/src/public/`, `01-traditional-flow/python-app/test/`, `01-traditional-flow/java-app/src/main/java/com/andrea/devops/`, `01-traditional-flow/java-app/src/main/resources/static/`, `01-traditional-flow/java-app/src/test/java/com/andrea/devops/`, `02-docker-flow/java-docker-app/`, `infra/`, `.github/workflows/`
  - Crear un `.gitkeep` en cada carpeta vacía para que Git las rastree
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Implementar la Interfaz Web Unificada (HTML + CSS)
  - [x] 2.1 Crear `index.html` con el contenido requerido
    - Incluir `<h1>Prueba de Despliegue Exitosa 🚀</h1>`
    - Incluir `<h2>Charla: Despliegue 101 - Por Andrea Rosero</h2>`
    - Incluir botón/enlace "Ver Documentación del Repositorio" apuntando a la URL del repositorio en GitHub
    - Referenciar `style.css` como hoja de estilos externa
    - _Requirements: 2.1, 2.2, 2.3, 2.7_

  - [x] 2.2 Crear `style.css` con el diseño Dark Mode
    - Fondo con degradado de `#1a1a2e` a `#16213e`/`#0f3460`
    - Tipografía `Inter` o `Roboto`, centrada con Flexbox (`display: flex; align-items: center; justify-content: center`)
    - Breakpoints responsive: tablet (≤768px) y móvil (≤480px)
    - Transición `hover` en el botón (transform + box-shadow)
    - _Requirements: 2.4, 2.5, 2.6, 2.8_

  - [x] 2.3 Copiar `index.html` y `style.css` a las tres aplicaciones
    - Colocar copias idénticas en `javascript-app/src/public/`, `python-app/src/public/` y `java-app/src/main/resources/static/`
    - _Requirements: 2.9_

- [x] 3. Implementar la Aplicación JavaScript (Node.js/Express)
  - [x] 3.1 Crear `package.json`
    - Definir `name: "javascript-app"`, `version: "1.0.0"`
    - Scripts: `"start": "node src/server.js"`, `"test": "jest"`
    - Dependencias con versiones fijadas: `express`
    - DevDependencies con versiones fijadas: `jest`, `supertest`
    - _Requirements: 3.1_

  - [x] 3.2 Crear `src/server.js`
    - Configurar Express con `PORT = process.env.PORT ?? 80`
    - Servir archivos estáticos de `src/public/` en la ruta `/`
    - Exponer `GET /health` que retorne `{ "status": "UP", "charla": "Despliegue 101 con JavaScript" }` con HTTP 200
    - Exportar `app` para que Supertest pueda importarla sin iniciar el servidor
    - _Requirements: 3.2, 3.3, 3.4_

  - [x] 3.3 Crear `test/app.test.js`
    - Importar `app` desde `src/server.js` usando Supertest
    - Prueba 1: `GET /health` responde con HTTP 200
    - Prueba 2: `GET /health` retorna JSON con `status: "UP"` y campo `charla`
    - Incluir comentarios educativos explicando la relación con el Check_Verde
    - _Requirements: 3.5, 3.6, 3.7_

  - [ ]* 3.4 Ejecutar `npm install` y `npm test` en `javascript-app/` para verificar que las pruebas pasan
    - _Requirements: 3.6_

- [~] 4. Checkpoint — Verificar JS App
  - Asegurarse de que `npm test` en `javascript-app/` retorna código de salida `0`. Consultar al usuario si hay dudas.

- [x] 5. Implementar la Aplicación Python (Flask)
  - [x] 5.1 Crear `requirements.txt`
    - Incluir `Flask==<versión fijada>`, `pytest==<versión fijada>`, `pytest-flask==<versión fijada>`
    - _Requirements: 4.1_

  - [x] 5.2 Crear `src/app.py`
    - Configurar Flask con `port = int(os.environ.get("PORT", 80))`
    - Servir `src/public/index.html` en la ruta `/` usando `send_from_directory`
    - Exponer `GET /health` que retorne `{ "status": "UP", "charla": "Despliegue 101 on Python" }` con HTTP 200
    - Exponer la instancia `app` de Flask para que pytest-flask pueda importarla
    - _Requirements: 4.2, 4.3, 4.4_

  - [x] 5.3 Crear `test/test_app.py`
    - Definir fixture `client` usando `app.test_client()`
    - Prueba 1: `GET /health` responde con HTTP 200
    - Prueba 2: `GET /health` retorna JSON con `status: "UP"` y campo `charla`
    - Incluir comentarios educativos
    - _Requirements: 4.5, 4.6, 4.7_

  - [ ]* 5.4 Ejecutar `pip install -r requirements.txt` y `pytest` en `python-app/` para verificar que las pruebas pasan
    - _Requirements: 4.6_

- [~] 6. Checkpoint — Verificar Python App
  - Asegurarse de que `pytest` en `python-app/` retorna código de salida `0`. Consultar al usuario si hay dudas.

- [ ] 7. Implementar la Aplicación Java (Spring Boot 3)
  - [x] 7.1 Crear `pom.xml`
    - Parent: `spring-boot-starter-parent` versión `3.x.x`
    - Java source/target: `17`
    - Dependencias: `spring-boot-starter-web`, `spring-boot-starter-test`
    - Plugin: `spring-boot-maven-plugin`
    - _Requirements: 5.5_

  - [x] 7.2 Crear `src/main/resources/application.properties`
    - Definir `server.port=80`
    - _Requirements: 5.2_

  - [x] 7.3 Crear `Application.java`
    - Clase principal con `@SpringBootApplication` y método `main()` que llama a `SpringApplication.run()`
    - Ubicar en `src/main/java/com/andrea/devops/`
    - _Requirements: 5.1_

  - [x] 7.4 Crear `HealthController.java`
    - Anotar con `@RestController`
    - Método `GET /health` anotado con `@GetMapping("/health")` que retorne un `Map<String, String>` con `status: "UP"` y `charla: "Despliegue 101 con Java"`
    - Respuesta con HTTP 200 y `Content-Type: application/json`
    - Ubicar en `src/main/java/com/andrea/devops/`
    - _Requirements: 5.3, 5.4_

  - [ ] 7.5 Crear `ApplicationTests.java`
    - Anotar con `@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)`
    - Inyectar `TestRestTemplate`
    - Prueba 1: el contexto de Spring carga correctamente (`@Test` vacío o con `assertNotNull`)
    - Prueba 2: `GET /health` retorna HTTP 200
    - Prueba 3: `GET /health` retorna `Content-Type: application/json`
    - Prueba 4: `GET /health` retorna body con `status: "UP"` y campo `charla`
    - Incluir comentarios educativos que expliquen la relación con el Check_Verde de GitHub Actions
    - Ubicar en `src/test/java/com/andrea/devops/`
    - _Requirements: 5.6, 5.7, 5.8_

  - [ ]* 7.6 Ejecutar `mvn clean test` en `java-app/` para verificar que las pruebas pasan
    - _Requirements: 5.8_

- [~] 8. Checkpoint — Verificar Java App
  - Asegurarse de que `mvn clean test` en `java-app/` retorna código de salida `0`. Consultar al usuario si hay dudas.

- [ ] 9. Implementar la Aplicación Java con Docker (Bonus)
  - [~] 9.1 Copiar el código fuente de `java-app/` a `02-docker-flow/java-docker-app/`
    - Copiar `pom.xml`, `src/` completo (incluyendo `application.properties` y archivos estáticos)
    - No modificar ningún archivo del código fuente
    - _Requirements: 6.1_

  - [~] 9.2 Crear `Dockerfile` multi-etapa en `02-docker-flow/java-docker-app/`
    - Etapa 1 (`build`): imagen base `maven:3.9-eclipse-temurin-17`, copiar fuentes, ejecutar `mvn package -DskipTests`, producir JAR en `target/`
    - Etapa 2 (`runtime`): imagen base `eclipse-temurin:17-jre`, copiar el JAR desde la etapa `build`, exponer puerto `8080`, definir `ENTRYPOINT ["java", "-jar", "app.jar"]`
    - Incluir comentarios educativos que expliquen cada etapa
    - _Requirements: 6.2, 6.3, 6.4_

- [ ] 10. Implementar los Pipelines de GitHub Actions
  - [~] 10.1 Crear `.github/workflows/03-java-traditional-cd.yml` (Pipeline Java)
    - Trigger: `push` con `paths: ['01-traditional-flow/java-app/**']`
    - Runner: `ubuntu-latest`
    - Job: `control-de-calidad`
    - Steps: `actions/checkout@v4`, `actions/setup-java@v4` (Java 17, distribución Temurin), `mvn -f 01-traditional-flow/java-app/pom.xml clean test`
    - Incluir comentarios educativos en cada step explicando su propósito y la relación con el Check_Verde
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 11.1, 11.2, 11.3_

  - [~] 10.2 Crear `.github/workflows/01-js-traditional-cd.yml` (Pipeline JS)
    - Trigger: `push` con `paths: ['01-traditional-flow/javascript-app/**']`
    - Runner: `ubuntu-latest`
    - Job: `control-de-calidad`
    - Steps: `actions/checkout@v4`, `actions/setup-node@v4` (Node 20), `npm install --prefix 01-traditional-flow/javascript-app`, `npm test --prefix 01-traditional-flow/javascript-app`
    - Incluir comentarios educativos que resalten la similitud estructural con el Pipeline Java
    - _Requirements: 8.1, 8.2, 8.5, 8.7, 8.9, 8.11_

  - [~] 10.3 Crear `.github/workflows/02-python-traditional-cd.yml` (Pipeline Python)
    - Trigger: `push` con `paths: ['01-traditional-flow/python-app/**']`
    - Runner: `ubuntu-latest`
    - Job: `control-de-calidad`
    - Steps: `actions/checkout@v4`, `actions/setup-python@v5` (Python 3.11), `pip install -r 01-traditional-flow/python-app/requirements.txt`, `pytest 01-traditional-flow/python-app/test/`
    - Incluir comentarios educativos que resalten la similitud estructural con el Pipeline Java
    - _Requirements: 8.3, 8.4, 8.6, 8.8, 8.10, 8.12_

  - [~] 10.4 Crear `.github/workflows/04-java-docker-evolved-cd.yml` (Pipeline Docker)
    - Trigger: `push` con `paths: ['02-docker-flow/java-docker-app/**']`
    - Runner: `ubuntu-latest`
    - Job: `control-de-calidad`
    - Steps: `actions/checkout@v4`, `docker build ./02-docker-flow/java-docker-app`
    - Incluir comentarios educativos que expliquen la diferencia entre el flujo tradicional y el flujo con Docker
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 11. Implementar los Scripts de Infraestructura EC2
  - [~] 11.1 Crear `infra/ec2-js-setup.sh`
    - Agregar `#!/bin/bash` y `set -e` al inicio
    - Instalar Node.js (verificar con `command -v node` antes de instalar)
    - Clonar el repositorio (verificar si el directorio existe; si existe, hacer `git pull`)
    - Configurar la JS_App como servicio systemd (verificar con `systemctl is-enabled` antes de crear el unit file)
    - Habilitar e iniciar el servicio
    - Incluir comentarios en español en cada sección
    - _Requirements: 10.1, 10.5, 10.6_

  - [~] 11.2 Crear `infra/ec2-python-setup.sh`
    - Agregar `#!/bin/bash` y `set -e` al inicio
    - Instalar Python 3 y pip (verificar con `command -v python3` antes de instalar)
    - Clonar el repositorio (verificar si el directorio existe; si existe, hacer `git pull`)
    - Configurar la Python_App como servicio systemd (verificar idempotencia)
    - Habilitar e iniciar el servicio
    - Incluir comentarios en español en cada sección
    - _Requirements: 10.2, 10.5, 10.6_

  - [~] 11.3 Crear `infra/ec2-java-setup.sh`
    - Agregar `#!/bin/bash` y `set -e` al inicio
    - Instalar Java 17 (verificar con `command -v java` antes de instalar)
    - Clonar el repositorio (verificar si el directorio existe; si existe, hacer `git pull`)
    - Configurar la Java_App como servicio systemd (verificar idempotencia)
    - Habilitar e iniciar el servicio
    - Incluir comentarios en español en cada sección
    - _Requirements: 10.3, 10.5, 10.6_

  - [~] 11.4 Crear `infra/ec2-docker-setup.sh`
    - Agregar `#!/bin/bash` y `set -e` al inicio
    - Instalar Docker (verificar con `command -v docker` antes de instalar)
    - Clonar el repositorio (verificar si el directorio existe; si existe, hacer `git pull`)
    - Construir y ejecutar la Java_Docker_App como contenedor Docker
    - Incluir comentarios en español en cada sección
    - _Requirements: 10.4, 10.5, 10.6_

- [~] 12. Crear el README.md raíz
  - Explicar el propósito educativo del proyecto ("Despliegue 101" por Andrea Rosero)
  - Describir la estructura de carpetas con un árbol de directorios
  - Explicar cómo ejecutar cada aplicación localmente
  - Explicar cómo funcionan los pipelines de CI y qué es el Check_Verde
  - Mencionar que la Fase 1 cubre solo CI y que el despliegue en AWS EC2 es para fases futuras
  - _Requirements: 1.5_

- [~] 13. Checkpoint Final — Verificar estructura completa
  - Confirmar que todos los archivos requeridos por el Req. 1 existen en las rutas correctas
  - Confirmar que `index.html` contiene los textos exactos de Req. 2.1–2.3
  - Confirmar que los cuatro archivos YAML de pipelines existen en `.github/workflows/`
  - Confirmar que los cuatro scripts de EC2 existen en `infra/`
  - Consultar al usuario si hay dudas.

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia los requisitos específicos para trazabilidad
- Los checkpoints garantizan validación incremental antes de continuar
- No se aplican property-based tests: los endpoints retornan respuestas fijas y el diseño lo excluye explícitamente
- El `index.html` y `style.css` son idénticos en las tres aplicaciones; crear una sola vez y copiar
- La Java_Docker_App reutiliza el código fuente de `java-app/` sin modificaciones (Req. 6.1)
- Los scripts EC2 deben usar `set -e` para fallar rápido ante errores

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1"] },
    { "id": 1, "tasks": ["2.1", "2.2"] },
    { "id": 2, "tasks": ["2.3"] },
    { "id": 3, "tasks": ["3.1", "5.1", "7.1"] },
    { "id": 4, "tasks": ["3.2", "5.2", "7.2", "7.3"] },
    { "id": 5, "tasks": ["3.3", "5.3", "7.4"] },
    { "id": 6, "tasks": ["3.4", "5.4", "7.5"] },
    { "id": 7, "tasks": ["7.6", "9.1"] },
    { "id": 8, "tasks": ["9.2"] },
    { "id": 9, "tasks": ["10.1", "10.2", "10.3", "10.4"] },
    { "id": 10, "tasks": ["11.1", "11.2", "11.3", "11.4"] },
    { "id": 11, "tasks": ["12"] }
  ]
}
```
