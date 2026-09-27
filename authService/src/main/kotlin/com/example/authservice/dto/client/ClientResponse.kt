package com.example.authservice.dto.client

import com.example.authservice.dto.user.UserResponse
import com.example.authservice.dto.user.toResponse
import com.example.authservice.entity.ClientEntity

data class ClientResponse(
    val id: String,
    val name: String,
    val privateKey: String?,
    val publicKey: String?,
    val users: List<UserResponse> = emptyList()
)

// Add a flag to optionally map users
fun ClientEntity.toResponse(withUsers: Boolean = false): ClientResponse {
    return ClientResponse(
        id = this.clientId,
        name = this.name,
        privateKey = this.privateKey,
        publicKey = this.publicKey,
        users = if (withUsers) {
            try {
                // Safely map users; if null or empty, return empty list
                this.users?.map { it.toResponse() } ?: emptyList()
            } catch (ex: Exception) {
                // Catch LazyInitializationException or any other
                emptyList()
            }
        } else {
            emptyList()
        }
    )
}

