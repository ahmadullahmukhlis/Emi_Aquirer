package com.example.authservice.repository


import com.example.authservice.entity.ClientEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ClientRepository : JpaRepository<ClientEntity, Long> {
    fun findByClientId(clientId: String): ClientEntity?
}
