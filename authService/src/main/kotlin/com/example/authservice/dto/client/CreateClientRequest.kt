package com.example.authservice.dto.client

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class CreateClientRequest(
    @field:NotBlank(message = "Name must not be blank")
    @field:Size(max = 100, message = "Name must be at most 100 characters")
    val name: String
)
