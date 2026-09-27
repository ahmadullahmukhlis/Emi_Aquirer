package com.example.authservice.repository

import com.example.authservice.entity.PermissionGroupEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PermissionGroupRepository : JpaRepository<PermissionGroupEntity, Long> {

    /**
     * Find a permission group by its unique name.
     * Used by the service to prevent duplicates during creation/update.
     */
    fun findByName(name: String): PermissionGroupEntity?
}
