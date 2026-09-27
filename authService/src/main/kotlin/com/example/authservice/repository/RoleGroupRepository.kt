package com.example.authservice.repository

import com.example.authservice.entity.RoleGroupEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface RoleGroupRepository : JpaRepository<RoleGroupEntity, Long> {
    fun findByName(name: String): RoleGroupEntity?
}
