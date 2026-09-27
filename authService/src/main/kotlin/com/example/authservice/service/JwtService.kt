package com.example.authservice.service

import com.example.authservice.entity.UserEntity
import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.util.*
import javax.crypto.SecretKey

@Service
class JwtService(
    @Value("\${jwt.auth.secret}") private val jwtSecret: String
) {

    private val secretKey: SecretKey = Keys.hmacShaKeyFor(jwtSecret.toByteArray())

    private val ACCESS_TOKEN_EXPIRATION = 15 * 60 * 1000
    private val REFRESH_TOKEN_EXPIRATION = 7 * 24 * 60 * 60 * 1000

    fun generateAccessToken(user: UserEntity): String {
        return createToken(user, ACCESS_TOKEN_EXPIRATION)
    }

    fun generateRefreshToken(user: UserEntity): String {
        return createToken(user, REFRESH_TOKEN_EXPIRATION)
    }

    private fun createToken(user: UserEntity, expirationMillis: Int): String {
        val now = Date()
        val expiry = Date(now.time + expirationMillis)
        return Jwts.builder()
            .subject(user.username)                 // store username
            // JWTs must contain simple values, not JPA entities. Serializing RoleEntity
            // follows its lazy user relationship and fails after the Hibernate session closes.
            .claim("roles", user.roles.map { it.name })
            .issuedAt(now)
            .expiration(expiry)
            .signWith(secretKey)
            .compact()
    }

    fun validateToken(token: String): Boolean {
        return try {
            getClaims(token)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun extractUsername(token: String): String {
        return getClaims(token).subject
    }

    fun extractRoles(token: String): List<String> {
        val roles = getClaims(token)["roles"]
        return if (roles is List<*>) roles.filterIsInstance<String>() else emptyList()
    }

    fun extractPermissions(token: String): List<String> {
        val permissions = getClaims(token)["permissions"]
        return if (permissions is List<*>) permissions.filterIsInstance<String>() else emptyList()
    }

    private fun getClaims(token: String): Claims {
        return Jwts.parser()
            .verifyWith(secretKey)
            .build()
            .parseSignedClaims(token)
            .payload
    }
}
