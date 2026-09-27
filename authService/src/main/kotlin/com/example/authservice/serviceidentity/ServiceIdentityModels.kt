package com.example.authservice.serviceidentity

import jakarta.validation.constraints.NotBlank
import java.time.Instant

data class CreateServiceKeyRequest(
    @field:NotBlank val serviceName: String,
    val scopes: Set<String> = emptySet(),
    val expiresAt: Instant? = null
)

/** `secret` is returned only by create/rotate and must be placed in a secret manager immediately. */
data class CreatedServiceKeyResponse(
    val id: String,
    val serviceName: String,
    val keyPrefix: String,
    val secret: String,
    val scopes: Set<String>,
    val expiresAt: Instant?
)

data class ServiceKeyResponse(
    val id: String,
    val serviceName: String,
    val keyPrefix: String,
    val scopes: Set<String>,
    val createdAt: Instant,
    val expiresAt: Instant?,
    val revokedAt: Instant?,
    val lastUsedAt: Instant?
)
