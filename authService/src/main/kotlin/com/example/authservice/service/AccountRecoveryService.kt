package com.example.authservice.service

import com.example.authservice.dto.response.Response
import com.example.authservice.entity.AccountActionTokenEntity
import com.example.authservice.repository.AccountActionTokenRepository
import com.example.authservice.repository.UserRepository
import org.springframework.beans.factory.annotation.Value
import org.springframework.mail.SimpleMailMessage
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import java.time.LocalDateTime
import java.util.Base64

@Service
class AccountRecoveryService(
    private val users: UserRepository,
    private val tokens: AccountActionTokenRepository,
    private val passwordEncoder: PasswordEncoder,
    private val mailSender: JavaMailSender,
    @Value("${'$'}{app.account-actions.public-url}") private val publicUrl: String,
    @Value("${'$'}{app.mail.from}") private val from: String
) {
    private val random = SecureRandom()

    @Transactional
    fun requestVerification(email: String): Response {
        val user = users.findByEmail(email.trim().lowercase())
        if (user != null && !user.emailVerified) send(user.id!!, user.email, "VERIFY_EMAIL", "/verify-email")
        return Response(true, "If the account needs verification, an email has been sent.", null)
    }

    @Transactional
    fun verifyEmail(token: String): Response {
        val action = consume(token, "VERIFY_EMAIL") ?: return Response(false, "This verification link is invalid or expired.", null)
        val user = users.findById(action.userId).orElse(null) ?: return Response(false, "Account not found.", null)
        user.emailVerified = true
        users.save(user)
        return Response(true, "Email verified. You can now sign in.", null)
    }

    @Transactional
    fun requestPasswordReset(email: String): Response {
        val user = users.findByEmail(email.trim().lowercase())
        if (user != null && user.enabled) send(user.id!!, user.email, "RESET_PASSWORD", "/reset-password")
        return Response(true, "If that account exists, a password-reset email has been sent.", null)
    }

    @Transactional
    fun resetPassword(token: String, password: String): Response {
        require(password.length >= 12) { "Password must contain at least 12 characters." }
        val action = consume(token, "RESET_PASSWORD") ?: return Response(false, "This reset link is invalid or expired.", null)
        val user = users.findById(action.userId).orElse(null) ?: return Response(false, "Account not found.", null)
        user.password = passwordEncoder.encode(password)!!
        users.save(user)
        return Response(true, "Password updated. You can now sign in.", null)
    }

    private fun send(userId: Long, email: String, purpose: String, route: String) {
        val raw = ByteArray(32).also(random::nextBytes)
        val token = Base64.getUrlEncoder().withoutPadding().encodeToString(raw)
        tokens.save(AccountActionTokenEntity(userId = userId, tokenHash = hash(token), purpose = purpose, expiresAt = LocalDateTime.now().plusMinutes(30)))
        val message = SimpleMailMessage().apply {
            from = this@AccountRecoveryService.from
            setTo(email)
            subject = if (purpose == "VERIFY_EMAIL") "Verify your AfPay portal email" else "Reset your AfPay portal password"
            text = "Open this secure link within 30 minutes:\n$publicUrl$route?token=$token\n\nIf you did not request this, you can ignore this email."
        }
        mailSender.send(message)
    }

    private fun consume(raw: String, purpose: String): AccountActionTokenEntity? {
        val action = tokens.findByTokenHash(hash(raw)) ?: return null
        if (action.purpose != purpose || action.usedAt != null || action.expiresAt.isBefore(LocalDateTime.now())) return null
        action.usedAt = LocalDateTime.now()
        return tokens.save(action)
    }

    private fun hash(value: String): String = MessageDigest.getInstance("SHA-256").digest(value.toByteArray(StandardCharsets.UTF_8)).joinToString("") { "%02x".format(it) }
}
