package com.example.authservice.repository

import com.example.authservice.entity.RoleEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface RoleRepository : JpaRepository<RoleEntity, Long> {

    /**
     * Find a role by its unique name.
     * Returns RoleEntity? (nullable) to stay consistent with Kotlin's null safety.
     */
    fun findByName(name: String): RoleEntity?
}
