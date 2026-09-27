package com.example.authservice.config

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.core.annotation.Order
import org.springframework.core.Ordered
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource
import org.springframework.web.filter.CorsFilter
import com.example.authservice.serviceidentity.ServiceKeyFilter

@Configuration
@EnableWebSecurity
class SecurityConfig(
    private val jwtFilter: JwtFilter,
    private val serviceKeyFilter: ServiceKeyFilter,
    @Value("\${app.cors.allowed-origins:*}") private val allowedOrigins: String
) {

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain {

        http
            .cors { it.configurationSource(corsConfigurationSource()) }
            .csrf { it.disable() }
            .sessionManagement {
                it.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            }
            .authorizeHttpRequests { auth ->
                auth
                    // allow preflight
                    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                    // public endpoints
                    .requestMatchers(
                        "/error",
                        "/login",
                        "/logout"
                    ).permitAll()
                    .requestMatchers("/account/**").denyAll()
                    .requestMatchers("/users", "/users/**").hasAnyAuthority("ADMIN", "SUPER_ADMIN")
                    .anyRequest().authenticated()
            }
            .exceptionHandling {
                it.authenticationEntryPoint { _, response, _ ->
                    response.status = 401
                    response.contentType = MediaType.APPLICATION_JSON_VALUE
                    response.writer.write("""{"status":false,"message":"Unauthorized"}""")
                }
                it.accessDeniedHandler { _, response, _ ->
                    response.status = 403
                    response.contentType = MediaType.APPLICATION_JSON_VALUE
                    response.writer.write("""{"status":false,"message":"Forbidden"}""")
                }
            }
            .formLogin { it.disable() }
            .httpBasic { it.disable() }

        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter::class.java)
        http.addFilterAfter(serviceKeyFilter, JwtFilter::class.java)

        return http.build()
    }

    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {

        val config = CorsConfiguration()

        val origins = allowedOrigins
            .split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }

        val hasWildcard = origins.any { it.contains("*") }
        if (hasWildcard) {
            // Use patterns to support wildcards like "*" or "https://*.example.com"
            config.allowedOriginPatterns = origins
        } else {
            config.allowedOrigins = origins
        }

        config.allowedMethods = listOf(
            "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"
        )

        config.allowedHeaders = listOf("*")

        // If you allow all origins, credentials must be false by spec
        config.allowCredentials = !origins.contains("*")
        config.maxAge = 3600L

        val source = UrlBasedCorsConfigurationSource()
        source.registerCorsConfiguration("/**", config)

        return source
    }

    // Ensure CORS headers are added even on error responses
    @Bean
    @Order(Ordered.HIGHEST_PRECEDENCE)
    fun corsFilter(): CorsFilter {
        return CorsFilter(corsConfigurationSource())
    }
}
