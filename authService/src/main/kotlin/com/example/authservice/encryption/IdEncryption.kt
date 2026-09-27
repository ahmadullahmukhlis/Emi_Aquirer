package com.example.authservice.encryption

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import java.util.*
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec
import java.security.MessageDigest

@Component
class IdEncryption {

    @Value("\${jwt.encryption.secret}")
    lateinit var secretKey: String

    // Generate a unique encrypted ID
    fun generateUniqueEncryptedId(): String {
        val uuid = UUID.randomUUID().toString()
        return encrypt(uuid)
    }

    fun encrypt(strToEncrypt: String): String {
        val key = MessageDigest.getInstance("SHA-256")
            .digest(secretKey.toByteArray(Charsets.UTF_8))
            .copyOf(16) // AES-128

        val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"))

        // URL-safe Base64 (replaces + with -, / with _, removes padding)
        return Base64.getUrlEncoder().withoutPadding()
            .encodeToString(cipher.doFinal(strToEncrypt.toByteArray(Charsets.UTF_8)))
    }

    fun decrypt(strToDecrypt: String): String {
        val key = MessageDigest.getInstance("SHA-256")
            .digest(secretKey.toByteArray(Charsets.UTF_8))
            .copyOf(16)

        val cipher = Cipher.getInstance("AES/ECB/PKCS5PADDING")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"))

        return String(cipher.doFinal(Base64.getUrlDecoder().decode(strToDecrypt)))
    }
}
