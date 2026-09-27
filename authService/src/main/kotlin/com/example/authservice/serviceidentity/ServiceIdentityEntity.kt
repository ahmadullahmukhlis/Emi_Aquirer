package com.example.authservice.serviceidentity

import jakarta.persistence.CollectionTable
import jakarta.persistence.Column
import jakarta.persistence.ElementCollection
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.Instant

/** A machine identity. The plaintext key is deliberately never persisted. */
@Entity
@Table(name = "service_api_keys", uniqueConstraints = [UniqueConstraint(columnNames = ["key_prefix"])])
class ServiceIdentityEntity(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Column(name = "service_name", nullable = false) var serviceName: String,
    @Column(name = "key_prefix", nullable = false, unique = true, length = 20) var keyPrefix: String,
    @Column(name = "key_hash", nullable = false, length = 100) var keyHash: String,
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "service_api_key_scopes", joinColumns = [JoinColumn(name = "service_key_id")])
    @Column(name = "scope", nullable = false)
    var scopes: MutableSet<String> = mutableSetOf(),
    @Column(nullable = false) var createdAt: Instant = Instant.now(),
    var expiresAt: Instant? = null,
    var revokedAt: Instant? = null,
    var lastUsedAt: Instant? = null
)
