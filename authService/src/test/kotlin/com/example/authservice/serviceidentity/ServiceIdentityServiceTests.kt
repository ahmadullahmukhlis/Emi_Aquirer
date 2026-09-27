package com.example.authservice.serviceidentity

import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest
class ServiceIdentityServiceTests @Autowired constructor(
    private val service: ServiceIdentityService,
    private val repository: ServiceIdentityRepository
) {
    @Test
    fun `generated service secret authenticates and is never stored in plaintext`() {
        val created = service.create(CreateServiceKeyRequest("routing-service", setOf("routing.read")))

        val stored = repository.findById(created.id).orElseThrow()
        assertNotEquals(created.secret, stored.keyHash)
        assertNotNull(service.authenticate(created.keyPrefix, created.secret))

        service.revoke(created.id)
        assertNull(service.authenticate(created.keyPrefix, created.secret))
    }
}
