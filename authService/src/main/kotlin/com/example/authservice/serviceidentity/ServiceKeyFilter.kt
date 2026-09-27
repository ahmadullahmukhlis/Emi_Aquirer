package com.example.authservice.serviceidentity

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

/** Guards service-only routes with a revocable, per-service key. */
@Component
class ServiceKeyFilter(private val identities: ServiceIdentityService) : OncePerRequestFilter() {
    override fun shouldNotFilter(request: HttpServletRequest) = !request.requestURI.removePrefix(request.contextPath).startsWith("/api/v1/internal/")

    override fun doFilterInternal(request: HttpServletRequest, response: HttpServletResponse, chain: FilterChain) {
        val identity = request.getHeader("X-Service-Id")?.let { id ->
            request.getHeader("X-Service-Key")?.let { secret -> identities.authenticate(id, secret) }
        }
        if (identity == null) {
            response.status = HttpServletResponse.SC_UNAUTHORIZED
            response.contentType = "application/json"
            response.writer.write("{\"message\":\"A valid service key is required\"}")
            return
        }
        val authorities = identity.scopes.map { SimpleGrantedAuthority("SCOPE_$it") }
        SecurityContextHolder.getContext().authentication = UsernamePasswordAuthenticationToken(identity.serviceName, null, authorities)
        chain.doFilter(request, response)
    }
}
