package com.andrea.devops;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pruebas de integración de la Java_App.
 *
 * ¿Qué es @SpringBootTest?
 * ─────────────────────────
 * Esta anotación le dice a Spring que levante el contexto completo de la
 * aplicación (igual que en producción) antes de ejecutar los tests.
 *
 * webEnvironment = RANDOM_PORT:
 *   Arranca un servidor Tomcat embebido en un puerto aleatorio disponible.
 *   Esto evita conflictos con el puerto 80 (que requiere permisos de root)
 *   y permite ejecutar los tests en cualquier entorno, incluyendo el runner
 *   de GitHub Actions.
 *
 * ¿Cómo se relaciona esto con el Check_Verde?
 * ─────────────────────────────────────────────
 * Cuando el Pipeline_Java ejecuta `mvn clean test` en GitHub Actions:
 *   1. Maven compila el código fuente.
 *   2. Spring Boot levanta la aplicación en un puerto aleatorio.
 *   3. TestRestTemplate hace peticiones HTTP reales al servidor.
 *   4. Si todos los @Test pasan → GitHub muestra el Check_Verde ✅
 *   5. Si algún @Test falla  → GitHub muestra el indicador de fallo ❌
 *
 * Estos tests son la "puerta de calidad" que garantiza que el código
 * funciona correctamente antes de cualquier despliegue.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApplicationTests {

    /**
     * @LocalServerPort inyecta el número de puerto aleatorio que eligió
     * Spring Boot al arrancar el servidor para los tests.
     * Lo usamos para construir la URL base de las peticiones HTTP.
     */
    @LocalServerPort
    private int port;

    /**
     * TestRestTemplate es el cliente HTTP de Spring Boot para tests de integración.
     * A diferencia de RestTemplate normal, está preconfigurado para:
     *   - No lanzar excepciones en respuestas 4xx/5xx (las retorna como ResponseEntity)
     *   - Apuntar automáticamente al servidor levantado por @SpringBootTest
     *
     * @Autowired le pide a Spring que inyecte la instancia gestionada por el contexto.
     */
    @Autowired
    private TestRestTemplate restTemplate;

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 1: Carga del contexto de Spring
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Verifica que el contexto de Spring carga correctamente.
     *
     * Este es el test más básico y el primero en ejecutarse. Si el contexto
     * no puede levantarse (por ejemplo, por un error de configuración en
     * application.properties o una dependencia mal declarada en pom.xml),
     * este test falla inmediatamente y todos los demás se omiten.
     *
     * En GitHub Actions: si este test falla, el Check_Verde nunca aparece.
     * Es la primera línea de defensa del pipeline de CI.
     */
    @Test
    void contextLoads() {
        // El contexto cargó correctamente si llegamos hasta aquí.
        // Verificamos adicionalmente que TestRestTemplate fue inyectado.
        assertThat(restTemplate).isNotNull();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2: GET /health retorna HTTP 200
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Verifica que el endpoint GET /health responde con código HTTP 200 OK.
     *
     * HTTP 200 significa que la petición fue procesada exitosamente.
     * Es el código de estado más importante para un health check:
     * los balanceadores de carga y los sistemas de monitoreo lo usan
     * para determinar si la aplicación está "viva" y puede recibir tráfico.
     *
     * En GitHub Actions: este test confirma que el servidor arrancó
     * correctamente y que el endpoint /health está registrado en Spring MVC.
     * Sin HTTP 200, el Check_Verde no aparece.
     */
    @Test
    void healthEndpointReturns200() {
        // Construimos la URL completa usando el puerto aleatorio asignado
        String url = "http://localhost:" + port + "/health";

        // TestRestTemplate hace una petición GET real al servidor embebido
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        // Verificamos que el código de estado sea exactamente 200 OK
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3: GET /health retorna Content-Type: application/json
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Verifica que el endpoint GET /health retorna Content-Type: application/json.
     *
     * El Content-Type le dice al cliente qué formato tiene el cuerpo de la
     * respuesta. "application/json" indica que el body es JSON válido.
     * Spring Boot (a través de Jackson) serializa automáticamente el
     * Map<String, String> retornado por HealthController a JSON y establece
     * este Content-Type en la cabecera de la respuesta.
     *
     * En GitHub Actions: este test garantiza que la serialización JSON
     * funciona correctamente. Si Jackson no estuviera en el classpath
     * (por ejemplo, si faltara spring-boot-starter-web en pom.xml),
     * este test fallaría y el Check_Verde no aparecería.
     */
    @Test
    void healthEndpointReturnsJson() {
        String url = "http://localhost:" + port + "/health";

        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        // Verificamos que el Content-Type incluya "application/json"
        // (Spring Boot puede agregar también el charset, ej: "application/json;charset=UTF-8")
        assertThat(response.getHeaders().getContentType())
                .isNotNull()
                .satisfies(contentType ->
                        assertThat(contentType.isCompatibleWith(MediaType.APPLICATION_JSON)).isTrue()
                );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4: GET /health retorna body con status="UP" y campo charla
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Verifica que el cuerpo de la respuesta de GET /health contiene:
     *   - El campo "status" con valor "UP"
     *   - El campo "charla" (con cualquier valor no nulo)
     *
     * Este test valida el contrato del Health_Endpoint definido en el
     * Requisito 5.3: la respuesta debe tener exactamente estos dos campos.
     *
     * ¿Por qué importa el campo "status": "UP"?
     * Los sistemas de monitoreo (como AWS ELB health checks) leen este campo
     * para determinar si la instancia está saludable. Si retorna "DOWN" o
     * el campo no existe, el balanceador deja de enviar tráfico a esa instancia.
     *
     * En GitHub Actions: este test es el más completo. Valida que toda la
     * cadena funciona: el controlador recibe la petición, construye el Map,
     * Jackson lo serializa a JSON, y el cliente lo deserializa correctamente.
     * Si este test pasa junto con los anteriores → Check_Verde ✅
     */
    @Test
    @SuppressWarnings("unchecked")
    void healthEndpointReturnsCorrectBody() {
        String url = "http://localhost:" + port + "/health";

        // Deserializamos directamente a Map para acceder a los campos por nombre
        ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

        Map<String, String> body = response.getBody();

        // El body no debe ser nulo
        assertThat(body).isNotNull();

        // El campo "status" debe existir y tener el valor exacto "UP"
        assertThat(body).containsKey("status");
        assertThat(body.get("status")).isEqualTo("UP");

        // El campo "charla" debe existir (su valor puede variar entre versiones)
        assertThat(body).containsKey("charla");
        assertThat(body.get("charla")).isNotBlank();
    }
}
