package com.example.authservice.dto.RoleGroup

import com.example.authservice.entity.RoleEntity
import jakarta.validation.constraints.NotBlank

data class RoleRequest(
    @field:NotBlank(message = "Role name is required")
    val name: String,
    val roleGroupId: Long? = null,
    val permissionIds: List<Long> = emptyList()
)


