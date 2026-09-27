package com.example.authservice.dto.permissiongroup

import jakarta.validation.constraints.NotBlank

data class PermissionGroupRequest(
    @field:NotBlank(message = "Permission group name is required")
    val name: String,
    val clientId: Long? = null
)