package com.example.authservice.service

import com.example.authservice.repository.UserRepository
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.User
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service

@Service
class CustomUserDetailsService(
    private val userRepository: UserRepository
) : UserDetailsService {

    override fun loadUserByUsername(username: String): UserDetails {
        val user = userRepository.findByUsername(username)
            ?: throw UsernameNotFoundException("User not found: $username")

        val authorities = user.roles
            .map { SimpleGrantedAuthority(it.name) }
            .toList()

        return User(
            user.username,
            user.password,
            user.enabled,
            true,
            true,
            true,
            authorities
        )
    }
}
