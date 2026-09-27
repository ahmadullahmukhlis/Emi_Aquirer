package com.example.authservice.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "account_action_tokens", indexes = [Index(name = "idx_account_action_token_hash", columnList = "token_hash")])
class AccountActionTokenEntity(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) var id: Long? = null,
    @Column(name = "user_id", nullable = false) var userId: Long,
    @Column(name = "token_hash", nullable = false, unique = true, length = 128) var tokenHash: String,
    @Column(nullable = false, length = 32) var purpose: String,
    @Column(name = "expires_at", nullable = false) var expiresAt: LocalDateTime,
    @Column(name = "used_at") var usedAt: LocalDateTime? = null,
    @Column(name = "created_at", nullable = false) var createdAt: LocalDateTime = LocalDateTime.now()
)
