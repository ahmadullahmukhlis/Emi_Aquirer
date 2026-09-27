package com.example.authservice.dto.RoleGroup

import com.example.authservice.entity.RoleEntity

data class RoleResponse(
    val id: Long?,
    val name: String,
    val roleGroupId: Long?,
    val roleGroupName: String?,
    val permissions: List<PermissionSimpleResponse> = emptyList()
)

data class PermissionSimpleResponse(
    val id: Long?,
    val name: String
)

/**
 * Extension function to convert RoleEntity to RoleResponse.
 * Safe, null-protected, and clean mapping.
 */
fun RoleEntity.toResponse(): RoleResponse {
    return RoleResponse(
        id = this.id,
        name = this.name,
        roleGroupId = this.roleGroup?.id,
        roleGroupName = this.roleGroup?.name ?: "No Group Assigned",
        permissions = this.permissions
            ?.map { permission ->
                PermissionSimpleResponse(
                    id = permission.id,
                    name = permission.name ?: "Unknown Permission"
                )
            }
            ?: emptyList()
    )
}
