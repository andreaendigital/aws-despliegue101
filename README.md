# 🚀 AWS Despliegue 101

**Charla educativa por Andrea Rosero**

Repositorio de acompañamiento para la charla *"Despliegue 101"*. Su objetivo es demostrar, de forma visual y práctica, que el proceso de Integración Continua (CI) sigue **el mismo patrón** sin importar el lenguaje de programación que uses.

---

## Propósito

Este repositorio responde a una pregunta muy común entre quienes están aprendiendo sobre despliegue:

> *"¿El proceso cambia si uso JavaScript, Python o Java?"*

La respuesta es **no**. El patrón de CI es universal:

1. Haces un `git push`
2. GitHub Actions detecta el cambio
3. Se instalan las dependencias del proyecto
4. Se ejecutan las pruebas automáticamente
5. Si todo pasa → ✅ **Check Verde** en GitHub

Este repositorio contiene tres aplicaciones web que hacen exactamente lo mismo, escritas en tres lenguajes distintos, para que puedas comparar los pipelines lado a lado y ver que la estructura es idéntica.

> **Fase 1 — Solo CI:** El alcance actual cubre únicamente la validación de calidad mediante Integración Continua. El despliegue en AWS EC2 queda para fases posteriores. Los scripts en `infra/` ya están preparados y se incluyen como referencia.

---

## Estructura del repositorio

```
aws-despliegue101/
├── .github/
│   └── workflows/
│       ├── 01-js-traditional-cd.yml        # Pipeline CI para JavaScript
│       ├── 02-python-traditional-cd.yml    # Pipeline CI para Python
│       ├── 03-java-traditional-cd.yml      # Pipeline CI para Java
│       └── 04-java-docker-evolved-cd.yml   # Pipeline CI para Docker (bonus)
│
├── 01-traditional-flow/                    # Las tres apps equivalentes
│   ├── javascript-app/
│   │   ├── src/
│   │   │   ├── server.js                   # Servidor Express
│   │   │   └── public/
│   │   │       ├── index.html
│   │   │       └── style.css
│   │   ├── test/
│   │   │   └── app.test.js                 # Pruebas con Jest + Supertest
│   │   └── package.json
│   │
│   ├── python-app/
│   │   ├── src/
│   │   │   ├── app.py                      # Servidor Flask
│   │   │   └── public/
│   │   │       ├── index.html
│   │   │       └── style.css
│   │   ├── test/
│   │   │   └── test_app.py                 # Pruebas con pytest
│   │   └── requirements.txt
│   │
│   └── java-app/
│       ├── src/
│       │   ├── main/java/com/andrea/devops/
│       │   │   ├── Application.java        # Clase principal Spring Boot
│       │   │   └── HealthController.java   # Endpoint /health
│       │   └── main/resources/
│       │       ├── application.properties
│       │       └── static/
│       │           ├── index.html
│       │           └── style.css
│       └── pom.xml
│
├── 02-docker-flow/                         # Bonus: la misma app Java en Docker
│   └── java-docker-app/
│       ├── src/                            # Mismo código fuente que java-app
│       ├── Dockerfile                      # Build multi-etapa con Maven + JRE
│       └── pom.xml
│
├── infra/                                  # Scripts EC2 para fases futuras
│   ├── ec2-js-setup.sh
│   ├── ec2-python-setup.sh
│   ├── ec2-java-setup.sh
│   └── ec2-docker-setup.sh
│
└── README.md
```

---

## Cómo ejecutar cada aplicación localmente

### Requisitos previos

| Herramienta | Versión mínima | Para qué se usa |
|-------------|---------------|-----------------|
| Node.js     | 20            | Aplicación JavaScript |
| Python      | 3.11          | Aplicación Python |
| Java + Maven | 17 + Maven 3  | Aplicación Java |
| Docker      | Cualquier versión reciente | App Docker (opcional) |

---

### JavaScript (Node.js/Express)

```bash
cd 01-traditional-flow/javascript-app
npm install
npm start
```

La aplicación queda disponible en `http://localhost:80`.

Para ejecutar las pruebas:

```bash
npm test
```

---

### Python (Flask)

```bash
cd 01-traditional-flow/python-app
pip install -r requirements.txt
python src/app.py
```

La aplicación queda disponible en `http://localhost:80`.

Para ejecutar las pruebas:

```bash
pytest test/
```

---

### Java (Spring Boot)

```bash
cd 01-traditional-flow/java-app
mvn spring-boot:run
```

La aplicación queda disponible en `http://localhost:80`.

Para ejecutar las pruebas:

```bash
mvn clean test
```

---

### Docker (bonus)

```bash
cd 02-docker-flow/java-docker-app
docker build -t java-docker-app .
docker run -p 8080:8080 java-docker-app
```

La aplicación queda disponible en `http://localhost:8080`.

> Nota: la app Docker usa el puerto `8080` en lugar de `80` para ilustrar la diferencia entre el flujo tradicional y el flujo con contenedores.

---

## Pipelines de CI y el Check Verde

### ¿Qué es el Check Verde?

Cuando haces un `git push`, GitHub Actions ejecuta automáticamente el pipeline correspondiente. Si todas las pruebas pasan, aparece un ✅ verde en la interfaz de GitHub junto a tu commit. Eso es el **Check Verde** — la confirmación visual de que tu código está en buen estado.

Si alguna prueba falla, aparece un ❌ rojo y GitHub te notifica. El código no se despliega (en fases futuras) hasta que el Check Verde esté presente.

### Los cuatro pipelines

Cada pipeline se activa automáticamente cuando haces push con cambios en la carpeta de su aplicación. La estructura de todos es idéntica — solo cambia el runtime y los comandos:

| Pipeline | Se activa cuando cambias... | Runtime | Comando de pruebas |
|----------|----------------------------|---------|-------------------|
| `01-js-traditional-cd.yml` | `01-traditional-flow/javascript-app/**` | Node.js 20 | `npm test` |
| `02-python-traditional-cd.yml` | `01-traditional-flow/python-app/**` | Python 3.11 | `pytest` |
| `03-java-traditional-cd.yml` | `01-traditional-flow/java-app/**` | Java 17 | `mvn clean test` |
| `04-java-docker-evolved-cd.yml` | `02-docker-flow/java-docker-app/**` | Docker | `docker build` |

### Cómo ver el Check Verde en acción

1. Haz cualquier cambio en una de las aplicaciones (por ejemplo, ajusta el tamaño de letra en `style.css`)
2. Haz commit y push:
   ```bash
   git add .
   git commit -m "Ajuste de estilo para demo"
   git push
   ```
3. Ve a la pestaña **Actions** de tu repositorio en GitHub
4. Verás el pipeline ejecutándose en tiempo real
5. En menos de 3 minutos, aparecerá el ✅ Check Verde

### ¿Por qué todos los pipelines tienen la misma estructura?

Porque el proceso de CI es universal. Compara el pipeline de JavaScript con el de Java:

```
Paso 1: Checkout del código        ← IDÉNTICO en todos
Paso 2: Configurar el runtime      ← Solo cambia: setup-node vs setup-java vs setup-python
Paso 3: Instalar dependencias      ← Solo cambia: npm install vs pip install vs mvn
Paso 4: Ejecutar pruebas           ← Solo cambia: npm test vs pytest vs mvn test
```

El patrón es siempre el mismo. Eso es exactamente lo que esta charla quiere demostrar.

---

## Fase 1 — Solo CI

El alcance actual de este repositorio cubre únicamente **Integración Continua (CI)**:

- ✅ Las tres aplicaciones tienen pruebas automatizadas
- ✅ Los cuatro pipelines ejecutan esas pruebas en cada push
- ✅ El Check Verde confirma que el código está en buen estado
- ⏳ El despliegue automático en AWS EC2 es para **fases futuras**

### Scripts de infraestructura (`infra/`)

La carpeta `infra/` contiene scripts de shell listos para configurar instancias EC2 en AWS. Están incluidos como referencia para que puedas ver cómo se vería la automatización del despliegue, pero no se ejecutan en la Fase 1.

| Script | Qué hace |
|--------|----------|
| `ec2-js-setup.sh` | Instala Node.js y configura la app JS como servicio |
| `ec2-python-setup.sh` | Instala Python y configura la app Python como servicio |
| `ec2-java-setup.sh` | Instala Java 17 y configura la app Java como servicio |
| `ec2-docker-setup.sh` | Instala Docker y ejecuta la app como contenedor |

Cada script está comentado en español para que puedas entender qué hace cada sección.

---

*Repositorio creado por Andrea Rosero para la charla "Despliegue 101".*
