package com.example.authservice.dto.RoleGroup

import com.example.authservice.entity.RoleGroupEntity
import java.time.LocalDateTime

data class RoleGroupResponse(
    val id: Long?,
    val name: String,
    val clientId: Long?,
    val clientName: String?,
    val roles: List<RoleSimpleResponse> = emptyList()
)

data class RoleSimpleResponse(
    val id: Long?,
    val name: String
)

/**
 * Extension function to convert Entity to DTO
 */
fun RoleGroupEntity.toResponse(): RoleGroupResponse {
    return RoleGroupResponse(
        id = this.id,
        name = this.name,
        clientId = this.client?.id,
        clientName = this.client?.name, // Assuming ClientEntity has a name field
        roles = this.roles.map { role ->
            RoleSimpleResponse(
                id = role.id,
                name = role.name // Assuming RoleEntity has a name field
            )
        }
    )
}
