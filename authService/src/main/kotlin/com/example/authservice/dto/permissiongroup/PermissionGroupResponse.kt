package com.example.authservice.dto.permissiongroup

import com.example.authservice.entity.PermissionGroupEntity

data class PermissionGroupResponse(
    val id: Long?,
    val name: String,
    val clientId: Long?,
    val clientName: String?,
    val permissions: List<PermissionSimpleResponse> = emptyList()
)

data class PermissionSimpleResponse(
    val id: Long?,
    val name: String
)

/**
 * Extension function to convert Entity to Response DTO
 */
fun PermissionGroupEntity.toResponse(): PermissionGroupResponse {
    return PermissionGroupResponse(
        id = this.id,
        name = this.name,
        clientId = this.client?.id,
        clientName = this.client?.name ?: "No Client Assigned",
        permissions = this.permissions.map {
            PermissionSimpleResponse(it.id, it.name ?: "")
        }
    )
}
