package com.example.authservice.config

import com.example.authservice.service.JwtService
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtFilter(
    private val jwtService: JwtService,
    private val userDetailsService: UserDetailsService
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {

        val authHeader = request.getHeader("Authorization")

        if (!authHeader.isNullOrEmpty() && authHeader.startsWith("Bearer ")) {

            val token = authHeader.substring(7)

            try {
                val username = jwtService.extractUsername(token)

                if (username != null &&
                    SecurityContextHolder.getContext().authentication == null &&
                    jwtService.validateToken(token)
                ) {

                    val userDetails = userDetailsService.loadUserByUsername(username)

                    val auth = UsernamePasswordAuthenticationToken(
                        userDetails,
                        null,
                        userDetails.authorities
                    )

                    SecurityContextHolder.getContext().authentication = auth
                }

            } catch (ex: Exception) {
                // Token expired, malformed, etc.
                println("JWT validation error: ${ex.message}")
            }
        }

        // Continue filter chain no matter what
        filterChain.doFilter(request, response)
    }
}
