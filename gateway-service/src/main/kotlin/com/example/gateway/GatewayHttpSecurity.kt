package com.example.gateway

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.web.SecurityFilterChain

/** Interactive identity belongs to the Portal. Execution endpoints authenticate their service caller. */
@Configuration
class GatewayHttpSecurity {
    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http.csrf { it.disable() }
            .authorizeHttpRequests { it
                .requestMatchers("/internal/portal/**").permitAll()
                // The public gateway accepts only transaction operations. Identity, keys,
                // applications, dashboards and administration remain in the Portal.
                .requestMatchers("/api/v1/mobile/transactions/purchase", "/api/v1/transactions/purchase", "/api/v1/transactions/*").permitAll()
                .anyRequest().denyAll()
            }
        return http.build()
    }
}
