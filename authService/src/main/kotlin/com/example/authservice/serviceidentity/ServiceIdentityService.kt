package com.example.authservice.serviceidentity

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Instant
import java.util.Base64
import java.util.UUID

@Service
class ServiceIdentityService(private val keys: ServiceIdentityRepository) {
    private val encoder = BCryptPasswordEncoder()
    private val random = SecureRandom()

    @Transactional
    fun create(request: CreateServiceKeyRequest): CreatedServiceKeyResponse {
        require(request.expiresAt == null || request.expiresAt.isAfter(Instant.now())) { "expiresAt must be in the future" }
        val prefix = "gws_" + UUID.randomUUID().toString().replace("-", "").take(12)
        val secret = "$prefix.${randomSecret()}"
        val entity = keys.save(ServiceIdentityEntity(
            serviceName = request.serviceName.trim(), keyPrefix = prefix, keyHash = requireNotNull(encoder.encode(secret)),
            scopes = request.scopes.map { it.trim() }.filter { it.isNotEmpty() }.toMutableSet(), expiresAt = request.expiresAt
        ))
        return CreatedServiceKeyResponse(entity.id!!, entity.serviceName, prefix, secret, entity.scopes, entity.expiresAt)
    }

    fun list() = keys.findAll().map(::toResponse)

    @Transactional
    fun revoke(id: String): ServiceKeyResponse {
        val key = keys.findById(id).orElseThrow { IllegalArgumentException("Service key not found") }
        key.revokedAt = Instant.now()
        return toResponse(keys.save(key))
    }

    @Transactional
    fun authenticate(serviceId: String, secret: String): ServiceIdentityEntity? {
        val key = keys.findByKeyPrefix(serviceId) ?: return null
        if (key.revokedAt != null || key.expiresAt?.isBefore(Instant.now()) == true || !encoder.matches(secret, key.keyHash)) return null
        key.lastUsedAt = Instant.now()
        return keys.save(key)
    }

    fun toResponse(key: ServiceIdentityEntity) = ServiceKeyResponse(key.id!!, key.serviceName, key.keyPrefix, key.scopes, key.createdAt, key.expiresAt, key.revokedAt, key.lastUsedAt)

    private fun randomSecret(): String {
        val bytes = ByteArray(32)
        random.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }
}
