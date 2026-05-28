# test_app.py — Pruebas automatizadas para la Python_App (Flask)
#
# ¿Por qué existen estas pruebas?
# --------------------------------
# En un pipeline de CI (Integración Continua), cada vez que hacemos `git push`
# GitHub Actions ejecuta estos tests automáticamente. Si todos pasan, aparece
# el famoso "Check_Verde" ✅ en la interfaz de GitHub, que confirma que el
# código está en buen estado antes de cualquier despliegue.
#
# Estas pruebas son el equivalente Python de las pruebas con Jest/Supertest
# en la JS_App y de los @SpringBootTest en la Java_App. El patrón es idéntico
# en los tres lenguajes: levantar la app, hacer una petición HTTP simulada
# y verificar la respuesta.
#
# Herramientas utilizadas:
#   - pytest       : framework de testing estándar en Python
#   - Flask test client : cliente HTTP integrado en Flask para simular peticiones
#                         sin necesidad de levantar un servidor real

import pytest

# Importamos la instancia `app` de Flask desde src/app.py.
# El conftest.py en la raíz de python-app/ ya agregó src/ al sys.path,
# por lo que este import funciona directamente.
from app import app


# ---------------------------------------------------------------------------
# Fixture: client
# ---------------------------------------------------------------------------
# Un "fixture" en pytest es una función que prepara recursos reutilizables
# para los tests. Al declarar `client` como parámetro en una función de test,
# pytest lo inyecta automáticamente.
#
# `app.test_client()` crea un cliente HTTP especial de Flask que simula
# peticiones reales (GET, POST, etc.) sin necesidad de un servidor en red.
# Esto hace que los tests sean rápidos, aislados y reproducibles.
# ---------------------------------------------------------------------------
@pytest.fixture
def client():
    """Crea y retorna un cliente de prueba de Flask."""
    # TESTING = True desactiva el manejo de errores de Flask para que
    # los errores se propaguen directamente a los tests (más fácil de depurar).
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


# ---------------------------------------------------------------------------
# Prueba 1: El endpoint /health responde con HTTP 200
# ---------------------------------------------------------------------------
# Req. 4.5 — La Python_App debe incluir un test que verifique HTTP 200.
# Req. 4.6 — Al ejecutar pytest, todas las pruebas deben pasar (exit code 0).
#
# Esta es la prueba más básica: confirma que el endpoint existe y está
# disponible. Un código 200 significa "OK" — el servidor procesó la
# petición correctamente.
# ---------------------------------------------------------------------------
def test_health_returns_200(client):
    """GET /health debe responder con código HTTP 200."""
    response = client.get("/health")

    # assert detiene el test con un mensaje claro si la condición es falsa
    assert response.status_code == 200, (
        f"Se esperaba HTTP 200 pero se recibió {response.status_code}"
    )


# ---------------------------------------------------------------------------
# Prueba 2: El endpoint /health retorna el JSON correcto
# ---------------------------------------------------------------------------
# Req. 4.7 — La respuesta debe contener `status: "UP"` y el campo `charla`.
#
# No basta con que el servidor responda; también debemos verificar que el
# contenido sea el esperado. Esta prueba valida la estructura del JSON,
# que es lo que consumiría un sistema de monitoreo o un orquestador como
# Kubernetes para saber si la aplicación está sana.
# ---------------------------------------------------------------------------
def test_health_returns_correct_json(client):
    """GET /health debe retornar JSON con status='UP' y campo charla."""
    response = client.get("/health")

    # get_json() deserializa el cuerpo de la respuesta como JSON.
    # Retorna None si el Content-Type no es application/json o si el
    # cuerpo no es JSON válido.
    data = response.get_json()

    assert data is not None, "La respuesta no contiene JSON válido"
    assert data["status"] == "UP", (
        f"Se esperaba status='UP' pero se recibió '{data.get('status')}'"
    )
    assert "charla" in data, (
        "El campo 'charla' no está presente en la respuesta JSON"
    )
