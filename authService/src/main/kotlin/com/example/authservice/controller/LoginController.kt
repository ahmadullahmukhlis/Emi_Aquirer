package com.example.authservice.controller

import com.example.authservice.dto.response.Response
import com.example.authservice.dto.user.LoginDto
import com.example.authservice.service.AuthService
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping()
class LoginController(
    private val authService: AuthService
) {

    @PostMapping("/login")
    fun login(@Valid @RequestBody request: LoginDto): Response {
        return authService.login(request)
    }

    @PostMapping("/refresh")
    fun refresh(@RequestParam refreshToken: String): Response {
        return authService.refreshToken(refreshToken)
    }

    @PostMapping("/logout")
    fun logout(@RequestParam refreshToken: String): Response {
        return authService.logout(refreshToken)
    }
}
