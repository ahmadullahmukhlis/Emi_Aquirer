package com.example.authservice.dto.user

import com.example.authservice.entity.UserEntity
import org.springframework.web.servlet.support.ServletUriComponentsBuilder
import java.time.LocalDateTime

data class UserResponse (
    val id: String? = null,
    val firstName : String,
    val lastName : String,
    val photo: String? = null,
    val username: String,
    val email: String,
    val enabled: Boolean,
    val createdAt: LocalDateTime?,
    val updatedAt: LocalDateTime?,
)

fun UserEntity.toResponse(): UserResponse {

    val fullPhotoUrl = this.Photo?.let { photoPath ->
        ServletUriComponentsBuilder
            .fromCurrentContextPath()
            .path("/")
            .path(photoPath.removePrefix("/"))
            .toUriString()
    }

    return UserResponse(
        id = this.userHid,
        firstName = this.firstName ?: "",   // FIX: nullable in entity, not nullable in response
        lastName = this.lastName ?: "",     // FIX: nullable in entity, not nullable in response
        photo = fullPhotoUrl,
        username = this.username,
        email = this.email,
        enabled = this.enabled,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}
