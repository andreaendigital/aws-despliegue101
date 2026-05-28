/**
 * test/app.test.js — Pruebas automatizadas de la JS_App
 *
 * ¿Por qué existen estas pruebas?
 * --------------------------------
 * Cada vez que hacemos `git push`, GitHub Actions ejecuta `npm test`.
 * Si TODAS las pruebas pasan → aparece el ✅ Check_Verde en GitHub.
 * Si alguna falla           → aparece el ❌ indicador de fallo.
 *
 * Estas pruebas son el "contrato" que le decimos al pipeline:
 *   "La aplicación está sana si /health responde 200 con el JSON correcto."
 *
 * Herramienta: Supertest
 * ----------------------
 * Supertest nos permite hacer peticiones HTTP reales a la app Express
 * sin necesidad de levantar un servidor en un puerto real.
 * Importamos `app` (el objeto Express exportado por server.js) y
 * Supertest se encarga del resto.
 */

const request = require('supertest');
const app = require('../src/server');

// describe() agrupa pruebas relacionadas bajo un nombre descriptivo.
// Cuando Jest muestra los resultados, verás este bloque como encabezado.
describe('GET /health', () => {

  /**
   * Prueba 1 — Código de estado HTTP 200
   * -------------------------------------
   * Verifica que el endpoint /health responde con HTTP 200 (OK).
   * Este es el requisito mínimo para el Check_Verde: si el servidor
   * está caído o la ruta no existe, recibiríamos 404 o 500 y el
   * pipeline fallaría aquí mismo.
   *
   * Relación con el pipeline (01-js-traditional-cd.yml):
   *   npm test → Jest ejecuta este it() → Supertest llama a GET /health
   *   → si status === 200, la prueba pasa → Check_Verde ✅
   */
  it('responde con HTTP 200', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
  });

  /**
   * Prueba 2 — Cuerpo JSON con status "UP" y campo charla
   * -------------------------------------------------------
   * Verifica que el cuerpo de la respuesta es JSON válido y contiene:
   *   - status: "UP"   → indica que el servicio está operativo
   *   - charla: <str>  → identifica de qué charla proviene esta app
   *
   * ¿Por qué validar el cuerpo y no solo el código HTTP?
   * Un servidor podría responder 200 con un HTML de error o un JSON
   * vacío. Validar el cuerpo garantiza que la lógica de negocio
   * también funciona correctamente, no solo que el servidor "vive".
   *
   * Relación con el pipeline:
   *   Si el JSON cambia accidentalmente (p. ej. alguien renombra
   *   "status" a "estado"), esta prueba falla → ❌ en GitHub → el
   *   equipo se entera antes de que llegue a producción.
   */
  it('retorna JSON con status "UP" y campo charla', async () => {
    const response = await request(app).get('/health');

    // Verificar que el Content-Type es application/json
    expect(response.headers['content-type']).toMatch(/application\/json/);

    // Verificar los campos del cuerpo
    expect(response.body.status).toBe('UP');
    expect(response.body).toHaveProperty('charla');
  });

});
