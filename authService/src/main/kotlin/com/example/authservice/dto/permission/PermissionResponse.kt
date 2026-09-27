package com.example.authservice.dto.permission

import com.example.authservice.entity.PermissionEntity

data class PermissionResponse(
    val id: Long?,
    val name: String,
    val permission: String,
    val groupId: Long?,
    val groupName: String?
)

/**
 * Extension function to convert Entity to Response DTO
 */
fun PermissionEntity.toResponse(): PermissionResponse {
    return PermissionResponse(
        id = this.id,
        name = this.name,
        permission = this.permission,
        groupId = this.permissionGroup?.id,
        groupName = this.permissionGroup?.name ?: "No Group"
    )
}
