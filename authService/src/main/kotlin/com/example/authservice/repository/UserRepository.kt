package com.example.authservice.repository

import com.example.authservice.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository


@Repository
interface UserRepository : JpaRepository<UserEntity, Long> {
    fun findByuserHid(userId: String): UserEntity?

    fun existsByEmail(email: String): Boolean
    fun existsByUsername(username: String): Boolean
    fun findByEmail(email: String): UserEntity?
    fun findByUsername(username: String): UserEntity?
}
