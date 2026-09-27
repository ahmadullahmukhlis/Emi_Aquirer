package com.example.authservice.exception

import com.example.authservice.dto.response.Response
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {

    /**
     * HANDLER 1: Exact Validation Errors (400 Bad Request)
     * Catches @Valid failures and returns field-specific messages.
     */
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationErrors(ex: MethodArgumentNotValidException): ResponseEntity<Response> {
        val fieldErrors = ex.bindingResult.fieldErrors.associate {
            it.field to (it.defaultMessage ?: "Invalid value")
        }

        val response = Response(
            status = false,
            message = "Validation Failed",
            data = fieldErrors // Result: {"email": "Email must be valid", "username": "required"}
        )
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response)
    }

    /**
     * HANDLER 2: All Other Errors (500 Internal Server Error)
     * Catches database crashes, null pointers, etc.
     */
    @ExceptionHandler(Exception::class)
    fun handleGeneralErrors(ex: Exception): ResponseEntity<Response> {
        val response = Response(
            status = false,
            message = "Internal Server Error",
            data = ex.message ?: "An unexpected error occurred"
        )
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response)
    }
}
