package com.example.authservice.service

import com.example.authservice.dto.permission.PermissionRequest
import com.example.authservice.dto.permission.PermissionResponse
import com.example.authservice.dto.permission.toResponse
import com.example.authservice.dto.response.Response
import com.example.authservice.entity.PermissionEntity
import com.example.authservice.repository.PermissionGroupRepository
import com.example.authservice.repository.PermissionRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
class PermissionService(
    private val permissionRepository: PermissionRepository,
    private val permissionGroupRepository: PermissionGroupRepository
) {

    @Transactional
    fun createPermission(request: PermissionRequest): Response {
        // Business Validation: Unique permission string
        if (permissionRepository.findByPermission(request.permission) != null) {
            return Response(false, "Permission string '${request.permission}' already exists", null)
        }

        val group = request.permissionGroupId?.let {
            permissionGroupRepository.findByIdOrNull(it) ?: return Response(false, "Permission Group not found", null)
        }

        val permission = PermissionEntity(
            name = request.name,
            permission = request.permission,
            permissionGroup = group
        )

        val saved = permissionRepository.save(permission)
        return Response(true, "Permission created successfully", saved.toResponse())
    }

    @Transactional
    fun update(id: Long, request: PermissionRequest): Response {
        val permission = permissionRepository.findByIdOrNull(id)
            ?: return Response(false, "Permission not found", null)

        // Check if updating to a permission string held by another entity
        val existing = permissionRepository.findByPermission(request.permission)
        if (existing != null && existing.id != id) {
            return Response(false, "Permission string already in use", null)
        }

        permission.name = request.name
        permission.permission = request.permission

        if (request.permissionGroupId != null) {
            permission.permissionGroup = permissionGroupRepository.findByIdOrNull(request.permissionGroupId)
        }

        val updated = permissionRepository.save(permission)
        return Response(true, "Permission updated successfully", updated.toResponse())
    }

    fun getAll(): List<PermissionResponse> = permissionRepository.findAll().map { it.toResponse() }

    fun getById(id: Long): Response {
        val permission = permissionRepository.findByIdOrNull(id)
        return if (permission != null) Response(true, "Permission found", permission.toResponse())
        else Response(false, "Permission not found", null)
    }

    @Transactional
    fun delete(id: Long): Response {
        val permission = permissionRepository.findByIdOrNull(id) ?: return Response(false, "Permission not found", null)
        permissionRepository.delete(permission)
        return Response(true, "Permission deleted", null)
    }
}
