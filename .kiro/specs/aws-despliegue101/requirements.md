# Requirements Document

## Introduction

`aws-despliegue101` es un repositorio educativo para la charla "Despliegue 101" presentada por Andrea Rosero. El objetivo central es demostrar que el proceso de despliegue es el mismo independientemente del lenguaje de programación. El repositorio contiene tres aplicaciones (JavaScript/Node.js, Python/Flask y Java/Spring Boot) que exponen exactamente la misma interfaz web, más un bonus con la aplicación Java desplegada mediante Docker. Cada aplicación tiene su propio pipeline de GitHub Actions. El alcance actual (Fase 1) cubre únicamente la validación de calidad mediante Integración Continua; el despliegue en AWS EC2 queda para fases posteriores.

## Glossary

- **Repositorio**: El proyecto `aws-despliegue101` alojado en GitHub.
- **Pipeline**: Flujo de automatización definido en GitHub Actions que se ejecuta al hacer push.
- **CI (Integración Continua)**: Práctica de ejecutar pruebas automáticas en cada push para validar la calidad del código antes de cualquier despliegue.
- **CD (Despliegue Continuo)**: Práctica de desplegar automáticamente a un entorno tras pasar CI. Fuera del alcance de la Fase 1.
- **Check_Verde**: Indicador visual en GitHub que confirma que todos los pasos del pipeline pasaron exitosamente.
- **JS_App**: Aplicación Node.js/Express ubicada en `01-traditional-flow/javascript-app/`.
- **Python_App**: Aplicación Python/Flask ubicada en `01-traditional-flow/python-app/`.
- **Java_App**: Aplicación Java/Spring Boot 3 ubicada en `01-traditional-flow/java-app/`.
- **Java_Docker_App**: Variante de la Java_App desplegada con Docker, ubicada en `02-docker-flow/java-docker-app/`.
- **Interfaz_Web**: Página HTML estática con estilo "cozy hacker" en Dark Mode, idéntica en las tres aplicaciones.
- **Pipeline_JS**: Workflow de GitHub Actions `01-js-traditional-cd.yml`.
- **Pipeline_Python**: Workflow de GitHub Actions `02-python-traditional-cd.yml`.
- **Pipeline_Java**: Workflow de GitHub Actions `03-java-traditional-cd.yml`.
- **Pipeline_Docker**: Workflow de GitHub Actions `04-java-docker-evolved-cd.yml`.
- **EC2_Script**: Script de shell en `infra/` que prepara una instancia EC2 para recibir una aplicación.
- **Health_Endpoint**: Endpoint REST `/health` de la Java_App que retorna el estado del servicio en formato JSON.
- **Maven**: Herramienta de construcción y gestión de dependencias para proyectos Java.

---

## Requirements

### Requirement 1: Estructura del Repositorio

**User Story:** Como asistente a la charla, quiero ver un repositorio organizado con carpetas claras por tecnología, para que pueda entender de un vistazo cómo se estructura un proyecto multi-lenguaje.

#### Acceptance Criteria

1. THE Repositorio SHALL contener la carpeta `01-traditional-flow/` con subcarpetas `javascript-app/`, `python-app/` y `java-app/`.
2. THE Repositorio SHALL contener la carpeta `02-docker-flow/` con subcarpeta `java-docker-app/`.
3. THE Repositorio SHALL contener la carpeta `.github/workflows/` con los archivos `01-js-traditional-cd.yml`, `02-python-traditional-cd.yml`, `03-java-traditional-cd.yml` y `04-java-docker-evolved-cd.yml`.
4. THE Repositorio SHALL contener la carpeta `infra/` con los scripts `ec2-js-setup.sh`, `ec2-python-setup.sh`, `ec2-java-setup.sh` y `ec2-docker-setup.sh`.
5. THE Repositorio SHALL contener un archivo `README.md` en la raíz que explique el propósito educativo del proyecto y la estructura de carpetas.

---

### Requirement 2: Interfaz Web Unificada

**User Story:** Como asistente a la charla, quiero ver la misma página web sin importar qué aplicación esté corriendo, para que quede demostrado visualmente que el pipeline es universal.

#### Acceptance Criteria

1. THE Interfaz_Web SHALL mostrar un encabezado H1 con el texto exacto "Prueba de Despliegue Exitosa 🚀".
2. THE Interfaz_Web SHALL mostrar un encabezado H2 con el texto exacto "Charla: Despliegue 101 - Por Andrea Rosero".
3. THE Interfaz_Web SHALL mostrar un botón o enlace con el texto "Ver Documentación del Repositorio" que apunte a la URL del Repositorio en GitHub.
4. THE Interfaz_Web SHALL aplicar un fondo con degradado de gris muy oscuro a azul medianoche/violeta profundo (Dark Mode estilo AWS).
5. THE Interfaz_Web SHALL usar tipografía sans-serif (Inter o Roboto), centrada horizontal y verticalmente mediante Flexbox o CSS Grid.
6. THE Interfaz_Web SHALL ser 100% responsiva y adaptarse correctamente a pantallas de escritorio, tablet y móvil.
7. THE Interfaz_Web SHALL separar los estilos en un archivo CSS independiente del HTML.
8. THE Interfaz_Web SHALL aplicar transiciones suaves en los elementos interactivos al hacer hover sobre el botón.
9. WHEN la JS_App sirve la Interfaz_Web, THE JS_App SHALL retornar el mismo contenido visual que la Python_App y la Java_App.

---

### Requirement 3: Aplicación JavaScript (Node.js/Express)

**User Story:** Como ponente, quiero una aplicación Node.js funcional con pruebas automatizadas, para que sirva como primer ejemplo del pipeline tradicional de CI.

#### Acceptance Criteria

1. THE JS_App SHALL incluir un archivo `package.json` con las dependencias `express` y `jest` (más `supertest` como devDependency), y los scripts `start` y `test`.
2. THE JS_App SHALL incluir el archivo `src/server.js` que configure Express en el puerto `80` por defecto (o el valor de la variable de entorno `PORT` si está definida), sirva los archivos estáticos de la carpeta `src/public/` en la ruta raíz `/`, y exponga una ruta `/health` que retorne un JSON `{ "status": "UP", "charla": "Despliegue 101" }` con código HTTP 200.
3. WHEN la variable de entorno `PORT` está definida, THE JS_App SHALL escuchar en el puerto indicado por dicha variable.
4. IF la variable de entorno `PORT` no está definida, THEN THE JS_App SHALL usar el puerto `80` como valor por defecto.
5. THE JS_App SHALL incluir el archivo `test/app.test.js` que use Supertest para validar que la ruta `/health` responde con código HTTP 200.
6. WHEN se ejecuta `npm test` en la carpeta `javascript-app/`, THE JS_App SHALL ejecutar todas las pruebas con Jest y retornar código de salida `0` si todas pasan.
7. WHEN al menos una prueba falla, THE JS_App SHALL retornar código de salida distinto de `0` y mostrar el nombre del test fallido.

---

### Requirement 4: Aplicación Python (Flask)

**User Story:** Como ponente, quiero una aplicación Python funcional con pruebas automatizadas, para que sirva como segundo ejemplo del pipeline tradicional de CI.

#### Acceptance Criteria

1. THE Python_App SHALL incluir un archivo `requirements.txt` con las dependencias `Flask` y `pytest` con versiones fijadas (más `pytest-flask` o similar para testing).
2. THE Python_App SHALL incluir el archivo `src/app.py` que configure Flask en el puerto `80` por defecto (o el valor de la variable de entorno `PORT` si está definida), sirva la Interfaz_Web en la ruta raíz `/`, y exponga una ruta `/health` que retorne un JSON `{ "status": "UP", "charla": "Despliegue 101" }` con código HTTP 200.
3. WHEN la variable de entorno `PORT` está definida, THE Python_App SHALL escuchar en el puerto indicado por dicha variable.
4. IF la variable de entorno `PORT` no está definida, THEN THE Python_App SHALL usar el puerto `80` como valor por defecto.
5. THE Python_App SHALL incluir el archivo `test/test_app.py` que use pytest para simular una petición HTTP a la ruta `/health` y verificar que responde con código HTTP 200.
6. WHEN se ejecuta `pytest` en la carpeta `python-app/`, THE Python_App SHALL ejecutar todas las pruebas y retornar código de salida `0` si todas pasan.
7. WHEN al menos una prueba falla, THE Python_App SHALL retornar código de salida distinto de `0` y mostrar el nombre del test fallido.

---

### Requirement 5: Aplicación Java (Spring Boot)

**User Story:** Como ponente, quiero una aplicación Java/Spring Boot funcional con pruebas automatizadas, para que sirva como tercer ejemplo del pipeline tradicional de CI y sea el foco de la demostración en vivo.

#### Acceptance Criteria

1. THE Java_App SHALL servir la Interfaz_Web como recurso estático en la ruta raíz `/` mediante Spring Boot 3 con Java 17.
2. THE Java_App SHALL escuchar en el puerto `80` según la propiedad `server.port=80` definida en `application.properties`.
3. THE Java_App SHALL exponer el Health_Endpoint en la ruta `/health` que retorne un JSON con el campo `status` con valor `"UP"` y el campo `charla` con valor `"Despliegue 101"`.
4. WHEN se realiza una petición GET a `/health`, THE Java_App SHALL responder con código HTTP 200 y Content-Type `application/json`.
5. THE Java_App SHALL incluir un archivo `pom.xml` con las dependencias `spring-boot-starter-web` y `spring-boot-starter-test`, configurado para Java 17.
6. THE Java_App SHALL incluir la clase `ApplicationTests.java` en `src/test/java/com/andrea/devops/` con anotación `@SpringBootTest` que valide la carga del contexto de Spring y que el Health_Endpoint responde con código HTTP 200.
7. THE Java_App SHALL incluir comentarios educativos en `ApplicationTests.java` que expliquen que este test produce el Check_Verde en GitHub Actions.
8. WHEN se ejecuta `mvn clean test` en la carpeta `java-app/`, THE Java_App SHALL compilar el proyecto, ejecutar todas las pruebas y retornar código de salida `0` si todas pasan.

---

### Requirement 6: Aplicación Java con Docker (Bonus)

**User Story:** Como ponente, quiero mostrar la misma aplicación Java empaquetada en Docker, para que los asistentes vean cómo la containerización es una evolución natural del flujo tradicional.

#### Acceptance Criteria

1. THE Java_Docker_App SHALL reutilizar el mismo código fuente Java de la Java_App sin modificaciones.
2. THE Java_Docker_App SHALL incluir un `Dockerfile` multi-etapa que compile el proyecto con Maven y genere una imagen final basada en `eclipse-temurin:17-jre`.
3. WHEN se construye la imagen Docker con `docker build`, THE Java_Docker_App SHALL producir una imagen que arranque la aplicación en el puerto `8080`.
4. WHEN se ejecuta el contenedor Docker, THE Java_Docker_App SHALL servir la Interfaz_Web en la ruta raíz `/` y responder con código HTTP 200.

---

### Requirement 7: Pipeline de CI para Java (Fase 1)

**User Story:** Como ponente, quiero que GitHub Actions ejecute las pruebas de la Java_App automáticamente en cada push, para que pueda demostrar en vivo el Check_Verde de Integración Continua y la reactivación automática del pipeline ante cualquier cambio.

#### Acceptance Criteria

1. THE Pipeline_Java SHALL activarse con el evento `push` únicamente cuando los cambios afecten archivos dentro de la ruta `01-traditional-flow/java-app/**`.
2. THE Pipeline_Java SHALL ejecutarse en un runner `ubuntu-latest`.
3. THE Pipeline_Java SHALL contener un job llamado `control-de-calidad` con los pasos: checkout del código, configuración de Java 17 y ejecución de `mvn -f 01-traditional-flow/java-app/pom.xml clean test`.
4. WHEN todas las pruebas de la Java_App pasan, THE Pipeline_Java SHALL producir un Check_Verde visible en la interfaz de GitHub.
5. WHEN al menos una prueba de la Java_App falla, THE Pipeline_Java SHALL producir un indicador de fallo visible en la interfaz de GitHub.
6. THE Pipeline_Java SHALL incluir comentarios en el archivo YAML que expliquen cada paso con fines educativos.
7. THE Pipeline_Java SHALL limitarse a validación de calidad (CI) en la Fase 1 y no incluir pasos de despliegue en AWS.

---

### Requirement 8: Pipelines de CI para JavaScript y Python (Fase 1)

**User Story:** Como ponente, quiero que GitHub Actions también valide las aplicaciones JavaScript y Python, para que la audiencia vea que el patrón de CI es idéntico en los tres lenguajes.

#### Acceptance Criteria

1. WHEN se realiza un push con cambios en `01-traditional-flow/javascript-app/**`, THE Pipeline_JS SHALL activarse automáticamente.
2. THE Pipeline_JS SHALL ejecutarse en un runner `ubuntu-latest` y contener un job llamado `control-de-calidad` con los pasos: checkout del código, configuración de Node.js 20, instalación de dependencias con `npm install`, y ejecución de `npm test --prefix 01-traditional-flow/javascript-app`.
3. WHEN se realiza un push con cambios en `01-traditional-flow/python-app/**`, THE Pipeline_Python SHALL activarse automáticamente.
4. THE Pipeline_Python SHALL ejecutarse en un runner `ubuntu-latest` y contener un job llamado `control-de-calidad` con los pasos: checkout del código, configuración de Python 3.11, instalación de dependencias con `pip install -r 01-traditional-flow/python-app/requirements.txt`, y ejecución de `pytest 01-traditional-flow/python-app/test/`.
5. WHEN todas las pruebas pasan, THE Pipeline_JS SHALL producir un Check_Verde visible en la interfaz de GitHub.
6. WHEN todas las pruebas pasan, THE Pipeline_Python SHALL producir un Check_Verde visible en la interfaz de GitHub.
7. WHEN al menos una prueba falla, THE Pipeline_JS SHALL producir un indicador de fallo visible en la interfaz de GitHub.
8. WHEN al menos una prueba falla, THE Pipeline_Python SHALL producir un indicador de fallo visible en la interfaz de GitHub.
9. THE Pipeline_JS SHALL incluir comentarios educativos en el archivo YAML que resalten la similitud estructural con el Pipeline_Java.
10. THE Pipeline_Python SHALL incluir comentarios educativos en el archivo YAML que resalten la similitud estructural con el Pipeline_Java.
11. THE Pipeline_JS SHALL limitarse a validación de calidad (CI) en la Fase 1 y no incluir pasos de despliegue en AWS.
12. THE Pipeline_Python SHALL limitarse a validación de calidad (CI) en la Fase 1 y no incluir pasos de despliegue en AWS.

---

### Requirement 9: Pipeline de CI para Docker (Fase 1 — Bonus)

**User Story:** Como ponente, quiero un pipeline para la aplicación Docker que valide la construcción de la imagen, para que la audiencia vea cómo Docker se integra en el mismo flujo de CI.

#### Acceptance Criteria

1. THE Pipeline_Docker SHALL activarse con el evento `push` cuando los cambios afecten archivos dentro de la ruta `02-docker-flow/java-docker-app/**`.
2. THE Pipeline_Docker SHALL contener un job llamado `control-de-calidad` con los pasos: checkout y construcción de la imagen Docker con `docker build`.
3. WHEN la imagen Docker se construye exitosamente, THE Pipeline_Docker SHALL producir un Check_Verde en GitHub.
4. THE Pipeline_Docker SHALL incluir comentarios educativos que expliquen la diferencia entre el flujo tradicional y el flujo con Docker.

---

### Requirement 10: Scripts de Infraestructura EC2

**User Story:** Como ponente, quiero scripts de configuración de EC2 listos para usar en fases futuras, para que la audiencia vea que la infraestructura también puede automatizarse.

#### Acceptance Criteria

1. THE EC2_Script para JavaScript SHALL instalar Node.js, clonar el Repositorio y configurar la JS_App como servicio systemd.
2. THE EC2_Script para Python SHALL instalar Python 3, pip, clonar el Repositorio y configurar la Python_App como servicio systemd.
3. THE EC2_Script para Java SHALL instalar Java 17, clonar el Repositorio y configurar la Java_App como servicio systemd.
4. THE EC2_Script para Docker SHALL instalar Docker, clonar el Repositorio y ejecutar la Java_Docker_App como contenedor.
5. THE EC2_Script SHALL incluir comentarios en español que expliquen cada sección del script con fines educativos.
6. WHEN el EC2_Script se ejecuta más de una vez en la misma instancia, THE EC2_Script SHALL completar sin errores y sin duplicar configuraciones.

---

### Requirement 11: Demostración de Integración Continua en Vivo

**User Story:** Como ponente, quiero poder hacer un cambio menor en el código (como ajustar el tamaño de letra en el CSS), hacer push y mostrar que el pipeline se reactiva automáticamente, para que la audiencia entienda el ciclo de CI en tiempo real.

#### Acceptance Criteria

1. WHEN se realiza un push con cualquier cambio en `01-traditional-flow/java-app/**`, THE Pipeline_Java SHALL iniciarse automáticamente sin intervención manual.
2. WHEN el Pipeline_Java se reactiva por un cambio menor en el CSS, THE Pipeline_Java SHALL completar el job `control-de-calidad` y producir un Check_Verde si las pruebas pasan.
3. THE Pipeline_Java SHALL completar la ejecución del job `control-de-calidad` en un tiempo razonable que permita la demostración en vivo sin esperas prolongadas.
