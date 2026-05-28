package com.andrea.devops;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Clase principal de la aplicación Java/Spring Boot.
 *
 * La anotación @SpringBootApplication activa:
 *   - @Configuration: permite definir beans en esta clase
 *   - @EnableAutoConfiguration: Spring Boot configura automáticamente el contexto
 *   - @ComponentScan: escanea los componentes del paquete com.andrea.devops
 *
 * Esta clase es el punto de entrada que arranca el servidor embebido (Tomcat)
 * y levanta toda la aplicación con un solo comando: mvn spring-boot:run
 */
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
