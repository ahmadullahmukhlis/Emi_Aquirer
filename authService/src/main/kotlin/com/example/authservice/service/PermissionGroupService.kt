package com.example.authservice.service

import com.example.authservice.dto.permissiongroup.PermissionGroupRequest
import com.example.authservice.dto.permissiongroup.PermissionGroupResponse
import com.example.authservice.dto.permissiongroup.toResponse
import com.example.authservice.dto.response.Response
import com.example.authservice.entity.PermissionGroupEntity
import com.example.authservice.repository.ClientRepository
import com.example.authservice.repository.PermissionGroupRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class PermissionGroupService(
    private val permissionGroupRepository: PermissionGroupRepository,
    private val clientRepository: ClientRepository
) {

    /**
     * CREATE PERMISSION GROUP
     */
    @Transactional
    fun createPermissionGroup(request: PermissionGroupRequest): Response {
        if (permissionGroupRepository.findByName(request.name) != null) {
            return Response(false, "Permission group name already exists", null)
        }

        val client = request.clientId?.let {
            clientRepository.findByIdOrNull(it) ?: return Response(false, "Client not found", null)
        }

        val permissionGroup = PermissionGroupEntity(
            name = request.name,
            client = client
        )

        val savedGroup = permissionGroupRepository.save(permissionGroup)
        return Response(true, "Permission group has been created", savedGroup.toResponse())
    }

    /**
     * UPDATE PERMISSION GROUP
     */
    @Transactional
    fun update(id: Long, request: PermissionGroupRequest): Response {
        val group = permissionGroupRepository.findByIdOrNull(id)
            ?: return Response(false, "Permission group not found", null)

        val existingWithName = permissionGroupRepository.findByName(request.name)
        if (existingWithName != null && existingWithName.id != id) {
            return Response(false, "Permission group name already in use", null)
        }

        group.name = request.name

        if (request.clientId != null) {
            val client = clientRepository.findByIdOrNull(request.clientId)
                ?: return Response(false, "Client not found", null)
            group.client = client
        }

        val updatedGroup = permissionGroupRepository.save(group)
        return Response(true, "Permission group has been updated", updatedGroup.toResponse())
    }

    /**
     * GET ALL
     */
    fun getAll(): List<PermissionGroupResponse> {
        return permissionGroupRepository.findAll().map { it.toResponse() }
    }

    /**
     * GET BY ID
     */
    fun getById(id: Long): Response {
        val group = permissionGroupRepository.findByIdOrNull(id)
        return if (group != null) {
            Response(true, "Permission group found", group.toResponse())
        } else {
            Response(false, "Permission group not found", null)
        }
    }

    /**
     * DELETE
     */
    @Transactional
    fun delete(id: Long): Response {
        val group = permissionGroupRepository.findByIdOrNull(id)
            ?: return Response(false, "Permission group not found", null)

        permissionGroupRepository.delete(group)
        return Response(true, "Permission group has been deleted", null)
    }
}
