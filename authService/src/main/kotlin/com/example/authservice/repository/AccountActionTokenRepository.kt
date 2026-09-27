package com.example.authservice.repository

import com.example.authservice.entity.AccountActionTokenEntity
import org.springframework.data.jpa.repository.JpaRepository

interface AccountActionTokenRepository : JpaRepository<AccountActionTokenEntity, Long> {
    fun findByTokenHash(tokenHash: String): AccountActionTokenEntity?
}
