package com.example.authservice.dto.permission

import jakarta.validation.constraints.NotBlank

data class PermissionRequest(
    @field:NotBlank(message = "Display name is required")
    val name: String,

    @field:NotBlank(message = "Permission string (e.g. USER_READ) is required")
    val permission: String,

    val permissionGroupId: Long? = null
)