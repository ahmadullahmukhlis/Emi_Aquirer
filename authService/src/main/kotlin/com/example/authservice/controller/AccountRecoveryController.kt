package com.example.authservice.controller

import com.example.authservice.dto.response.Response
import com.example.authservice.service.AccountRecoveryService
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import org.springframework.web.bind.annotation.*

data class EmailActionRequest(@field:Email @field:NotBlank val email: String)
data class TokenActionRequest(@field:NotBlank val token: String)
data class ResetPasswordRequest(@field:NotBlank val token: String, @field:NotBlank val password: String)

@RestController
@RequestMapping("/account")
class AccountRecoveryController(private val account: AccountRecoveryService) {
    @PostMapping("/request-email-verification") fun requestVerification(@RequestBody request: EmailActionRequest): Response = account.requestVerification(request.email)
    @PostMapping("/verify-email") fun verifyEmail(@RequestBody request: TokenActionRequest): Response = account.verifyEmail(request.token)
    @PostMapping("/forgot-password") fun forgotPassword(@RequestBody request: EmailActionRequest): Response = account.requestPasswordReset(request.email)
    @PostMapping("/reset-password") fun resetPassword(@RequestBody request: ResetPasswordRequest): Response = account.resetPassword(request.token, request.password)
}
