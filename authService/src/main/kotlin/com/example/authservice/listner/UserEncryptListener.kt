package com.example.authservice.listner;

import com.example.authservice.encryption.IdEncryption
import com.example.authservice.entity.UserEntity
import jakarta.persistence.PrePersist
import org.springframework.stereotype.Component

@Component
class UserEncryptListener(private val idEncryption: IdEncryption) {

    @PrePersist
    fun generateUserHid(user: UserEntity) {
        if (user.userHid.isEmpty()) {
            user.userHid = idEncryption.generateUniqueEncryptedId()
        }
    }
}
