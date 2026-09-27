package com.example.gateway

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebConfiguration(@param:Value("\${gateway.cors.allowed-origins:http://localhost:8082,http://localhost:8083}") private val origins: String, private val developerSecurity: DeveloperSecurity) : WebMvcConfigurer {
    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/**").allowedOrigins(*origins.split(",").map(String::trim).toTypedArray()).allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS").allowedHeaders("Authorization", "Content-Type", "Idempotency-Key")
    }
    override fun addInterceptors(registry: org.springframework.web.servlet.config.annotation.InterceptorRegistry) { registry.addInterceptor(developerSecurity).addPathPatterns("/api/v1/developer/**").excludePathPatterns("/api/v1/developer/oauth/token") }
}
