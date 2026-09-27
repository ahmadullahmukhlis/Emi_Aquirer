package com.example.authservice.dto.response

data class Response(
    val status: Boolean,
    val message: String,
    val data: Any? = null // optional payload
)