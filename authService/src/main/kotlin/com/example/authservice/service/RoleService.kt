package com.example.authservice.service
import com.example.authservice.dto.RoleGroup.RoleRequest
import com.example.authservice.dto.RoleGroup.toResponse
import com.example.authservice.dto.response.Response
import com.example.authservice.entity.RoleEntity
import com.example.authservice.repository.RoleGroupRepository
import com.example.authservice.repository.RoleRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import com.example.authservice.repository.PermissionRepository

@Service
class RoleService(
    private val roleRepository: RoleRepository,
    private val roleGroupRepository: RoleGroupRepository,
    private val permissionRepository: PermissionRepository
) {

    @Transactional
    fun createRole(request: RoleRequest): Response {
        if (roleRepository.findByName(request.name) != null) {
            return Response(false, "Role name already exists", null)
        }

        val roleGroup = request.roleGroupId?.let {
            roleGroupRepository.findByIdOrNull(it) ?: return Response(false, "Role Group not found", null)
        }

        val role = RoleEntity(name = request.name, roleGroup = roleGroup)

        // Handle Permissions
        if (request.permissionIds.isNotEmpty()) {
            val permissions = permissionRepository.findAllById(request.permissionIds)
            role.permissions.addAll(permissions)
        }

        val savedRole = roleRepository.save(role)
        return Response(true, "Role created successfully", savedRole.toResponse())
    }

    @Transactional
    fun updateRole(id: Long, request: RoleRequest): Response {
        val role = roleRepository.findByIdOrNull(id) ?: return Response(false, "Role not found", null)

        val existing = roleRepository.findByName(request.name)
        if (existing != null && existing.id != id) {
            return Response(false, "Role name already in use", null)
        }

        role.name = request.name
        role.roleGroup = request.roleGroupId?.let { roleGroupRepository.findByIdOrNull(it) }

        // Sync Permissions
        role.permissions.clear()
        val permissions = permissionRepository.findAllById(request.permissionIds)
        role.permissions.addAll(permissions)

        val updatedRole = roleRepository.save(role)
        return Response(true, "Role updated successfully", updatedRole.toResponse())
    }

    fun getById(id: Long): Response {
        val role = roleRepository.findByIdOrNull(id)
        return if (role != null) Response(true, "Role found", role.toResponse())
        else Response(false, "Role not found", null)
    }

    fun getAllRoles(): List<Any> = roleRepository.findAll().map { it.toResponse() }

    @Transactional
    fun delete(id: Long): Response {
        val role = roleRepository.findByIdOrNull(id) ?: return Response(false, "Role not found", null)
        roleRepository.delete(role)
        return Response(true, "Role deleted", null)
    }
}
