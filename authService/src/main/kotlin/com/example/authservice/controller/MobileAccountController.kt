package com.example.authservice.controller

import com.example.authservice.dto.user.UserResponse
import com.example.authservice.dto.user.toResponse
import com.example.authservice.repository.UserRepository
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/** Authenticated mobile identity endpoint. The username always comes from the verified JWT principal. */
@RestController
@RequestMapping("/mobile")
class MobileAccountController(private val users: UserRepository) {
    @GetMapping("/me")
    fun me(authentication: Authentication): UserResponse =
        users.findByUsername(authentication.name)?.toResponse()
            ?: throw IllegalArgumentException("Authenticated account was not found")
}
