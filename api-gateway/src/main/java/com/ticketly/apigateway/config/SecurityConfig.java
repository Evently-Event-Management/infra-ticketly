package com.ticketly.apigateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http
                .authorizeExchange(exchange -> exchange
                        // All routes passing through the gateway must be authenticated.
                        .anyExchange().authenticated()
                )
                // Configure the gateway as a Resource Server to validate incoming JWTs.
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                // Disable CSRF as we are using a stateless token-based approach.
                .csrf(ServerHttpSecurity.CsrfSpec::disable);

        return http.build();
    }
}
