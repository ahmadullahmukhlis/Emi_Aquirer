package com.example.authservice.service

import com.example.authservice.dto.RoleGroup.RoleGroupRequest
import com.example.authservice.dto.RoleGroup.toResponse
import com.example.authservice.dto.response.Response
import com.example.authservice.entity.RoleGroupEntity
import com.example.authservice.repository.ClientRepository
import com.example.authservice.repository.RoleGroupRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class RoleGroupService(
    private val roleGroupRepository: RoleGroupRepository,
    private val clientRepository: ClientRepository
) {

    /**
     * CREATE ROLE GROUP
     */
    @Transactional
    fun createRoleGroup(request: RoleGroupRequest): Response {

        // Check if name is unique
        if (roleGroupRepository.findByName(request.name) != null) {
            return Response(false, "Role group name already exists", null)
        }

        // Fetch client if provided
        val client = request.clientId?.let {
            clientRepository.findByIdOrNull(it) ?: return Response(false, "Client not found", null)
        }

        val roleGroup = RoleGroupEntity(
            name = request.name,
            client = client
        )

        val savedGroup = roleGroupRepository.save(roleGroup)
        return Response(true, "Role group has been created", savedGroup.toResponse())
    }

    /**
     * UPDATE ROLE GROUP
     */
    @Transactional
    fun updateRoleGroup(id: Long, request: RoleGroupRequest): Response {
        val roleGroup = roleGroupRepository.findByIdOrNull(id)
            ?: return Response(false, "Role group not found", null)

        // Validate name uniqueness if changed
        val existingWithName = roleGroupRepository.findByName(request.name)
        if (existingWithName != null && existingWithName.id != id) {
            return Response(false, "Role group name already in use", null)
        }

        // Update Client if provided
        if (request.clientId != null) {
            val client = clientRepository.findByIdOrNull(request.clientId)
                ?: return Response(false, "Client not found", null)
            roleGroup.client = client
        }

        roleGroup.name = request.name

        val updatedGroup = roleGroupRepository.save(roleGroup)
        return Response(true, "Role group has been updated", updatedGroup.toResponse())
    }

    /**
     * GET ROLE GROUP BY ID
     */
    fun getById(id: Long): Response {
        val roleGroup = roleGroupRepository.findByIdOrNull(id)
        return if (roleGroup != null) {
            Response(true, "Role group found", roleGroup.toResponse())
        } else {
            Response(false, "Role group not found", null)
        }
    }

    /**
     * GET ALL ROLE GROUPS
     */
    fun getAllRoleGroups(): List<Any> { // Using Any or specific RoleGroupResponse
        return roleGroupRepository.findAll().map { it.toResponse() }
    }

    /**
     * DELETE ROLE GROUP
     */
    @Transactional
    fun delete(id: Long): Response {
        val roleGroup = roleGroupRepository.findByIdOrNull(id)
            ?: return Response(false, "Role group not found", null)

        roleGroupRepository.delete(roleGroup)
        return Response(true, "Role group has been deleted", null)
    }
}
