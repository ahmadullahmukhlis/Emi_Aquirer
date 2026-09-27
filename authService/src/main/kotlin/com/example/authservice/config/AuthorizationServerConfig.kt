package com.example.authservice.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.crypto.factory.PasswordEncoderFactories
import org.springframework.security.crypto.password.PasswordEncoder

@Configuration
class AuthorizationServerConfig {
    @Bean
    fun passwordEncoder(): PasswordEncoder {
        // Automatically uses BCrypt as the default but supports migration
        return PasswordEncoderFactories.createDelegatingPasswordEncoder()
    }
}
