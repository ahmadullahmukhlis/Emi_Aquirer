package com.example.authservice.serviceidentity

import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/** Health/identity endpoint for extracted gateway services to verify their key integration. */
@RestController
@RequestMapping("/api/v1/internal")
class InternalServiceController {
    @GetMapping("/whoami")
    fun whoami(authentication: Authentication) = mapOf("service" to authentication.name, "scopes" to authentication.authorities.mapNotNull { it.authority?.removePrefix("SCOPE_") })
}
