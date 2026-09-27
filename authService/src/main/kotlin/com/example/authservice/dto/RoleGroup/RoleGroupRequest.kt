package com.example.authservice.dto.RoleGroup


import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class RoleGroupRequest(

    @field:NotBlank(message = "Role group name is required")
    @field:Size(min = 3, max = 50, message = "Name must be between 3 and 50 characters")
    val name: String,

    val clientId: Long? = null
)
