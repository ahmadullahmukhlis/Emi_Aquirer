package com.example.authservice.service

import org.springframework.stereotype.Service
import java.util.concurrent.ConcurrentHashMap

@Service
class RefreshTokenStore {

    // refreshToken -> username
    private val store: MutableMap<String, String> = ConcurrentHashMap()

    fun addToken(username: String, refreshToken: String) {
        store[refreshToken] = username
    }

    fun removeToken(refreshToken: String) {
        store.remove(refreshToken)
    }

    fun isValid(refreshToken: String): Boolean {
        return store.containsKey(refreshToken)
    }

    fun getUsername(refreshToken: String): String? {
        return store[refreshToken]
    }

    // ✅ Optional: remove all tokens for user (logout from all devices)
    fun removeAllForUser(username: String) {
        store.entries.removeIf { it.value == username }
    }
}
