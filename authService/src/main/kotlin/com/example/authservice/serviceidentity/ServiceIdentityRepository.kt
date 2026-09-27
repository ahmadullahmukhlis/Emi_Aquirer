package com.example.authservice.serviceidentity

import org.springframework.data.jpa.repository.JpaRepository

interface ServiceIdentityRepository : JpaRepository<ServiceIdentityEntity, String> {
    fun findByKeyPrefix(keyPrefix: String): ServiceIdentityEntity?
}
