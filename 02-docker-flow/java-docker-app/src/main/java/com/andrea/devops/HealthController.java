package com.andrea.devops;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Controlador REST que expone el endpoint de salud de la aplicación.
 *
 * La anotación @RestController combina dos anotaciones de Spring:
 *   - @Controller: marca esta clase como un componente web de Spring MVC
 *   - @ResponseBody: indica que el valor retornado por cada método se serializa
 *     directamente al cuerpo de la respuesta HTTP (en lugar de buscar una vista)
 *
 * Spring Boot detecta automáticamente esta clase gracias al @ComponentScan
 * activado por @SpringBootApplication en Application.java.
 */
@RestController
public class HealthController {

    /**
     * Endpoint de salud: GET /health
     *
     * La anotación @GetMapping("/health") mapea las peticiones HTTP GET
     * a la ruta "/health" hacia este método.
     *
     * Spring Boot serializa automáticamente el Map<String, String> retornado
     * a formato JSON usando Jackson (incluido en spring-boot-starter-web).
     * La respuesta tendrá:
     *   - Código HTTP: 200 OK (comportamiento por defecto de @RestController)
     *   - Content-Type: application/json
     *   - Body: {"status":"UP","charla":"Despliegue 101 con Java"}
     *
     * Este endpoint es el que validan las pruebas en ApplicationTests.java,
     * lo que produce el Check_Verde en GitHub Actions.
     *
     * @return Map con los campos "status" y "charla" del estado del servicio
     */
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of(
            "status", "UP",
            "charla", "Despliegue 101 con Java"
        );
    }
}
