package com.example.authservice.config

import com.example.authservice.entity.RoleEntity
import com.example.authservice.entity.UserEntity
import com.example.authservice.repository.RoleRepository
import com.example.authservice.repository.UserRepository
import org.springframework.beans.factory.annotation.Value
import org.springframework.boot.ApplicationRunner
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.transaction.annotation.Transactional

@Configuration
@ConditionalOnProperty(
    prefix = "app.bootstrap-admin",
    name = ["enabled"],
    havingValue = "true",
    matchIfMissing = true
)
class DefaultAdminInitializer(
    private val userRepository: UserRepository,
    private val roleRepository: RoleRepository,
    private val passwordEncoder: PasswordEncoder,
    @Value("\${app.bootstrap-admin.username:admin}") private val username: String,
    @Value("\${app.bootstrap-admin.password:Admin@123}") private val password: String,
    @Value("\${app.bootstrap-admin.email:admin@localhost}") private val email: String
) {

    @Bean
    fun createDefaultAdmin() = ApplicationRunner {
        createAdminIfMissing()
    }

    @Transactional
    fun createAdminIfMissing() {
        if (userRepository.existsByUsername(username) || userRepository.existsByEmail(email)) {
            return
        }

        val adminRole = roleRepository.findByName("ADMIN")
            ?: roleRepository.save(RoleEntity(name = "ADMIN"))

        val admin = UserEntity(
            username = username,
            firstName = "System",
            lastName = "Administrator",
            email = email,
            password = passwordEncoder.encode(password)!!,
            enabled = true,
            emailVerified = true
        )
        admin.roles.add(adminRole)
        userRepository.save(admin)
    }
}
