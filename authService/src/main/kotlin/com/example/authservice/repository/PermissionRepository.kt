package com.example.authservice.repository

import com.example.authservice.entity.PermissionEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PermissionRepository : JpaRepository<PermissionEntity, Long> {

    /**
     * Find by the unique security string (e.g., 'USER_CREATE')
     */
    fun findByPermission(permission: String): PermissionEntity?

    /**
     * Find by the display name (label)
     */
    fun findByName(name: String): PermissionEntity?

    /**
     * Quick check for existence by the unique security string
     */
    fun existsByPermission(permission: String): Boolean
}
