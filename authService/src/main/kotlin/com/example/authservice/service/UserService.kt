package com.example.authservice.service

import com.example.authservice.dto.response.Response
import com.example.authservice.dto.user.CreateUserRequest
import com.example.authservice.dto.user.UserResponse
import com.example.authservice.dto.user.toResponse
import com.example.authservice.entity.UserEntity
import com.example.authservice.repository.UserRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import org.springframework.web.servlet.support.ServletUriComponentsBuilder
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val accountRecovery: AccountRecoveryService
) {

    private val uploadDir = Paths.get("uploads")

    /**
     * CREATE USER
     */
    @Transactional
    fun createUser(request: CreateUserRequest, photo: MultipartFile?): Response {

        // Check username/email exists
        if (userRepository.existsByUsername(request.username)) {
            return Response(false, "Username already exists", null)
        }
        if (userRepository.existsByEmail(request.email)) {
            return Response(false, "Email already exists", null)
        }

        // Handle photo
        var photoPath: String? = null
        if (photo != null && !photo.isEmpty) {
            validateImage(photo)

            // ensure upload folder exists
            Files.createDirectories(uploadDir)

            val ext = photo.originalFilename?.substringAfterLast('.', "jpg")
            val fileName = UUID.randomUUID().toString() + "." + ext

            val filePath = uploadDir.resolve(fileName)
            photo.transferTo(filePath.toFile())

            // store relative path in DB
            photoPath = "images/$fileName"
        }

        val user = UserEntity(
            username = request.username,
            firstName = request.firstName,
            lastName = request.lastName,
            email = request.email,
            password = passwordEncoder.encode(request.password)!!,
            enabled = true,
            emailVerified = false,
            Photo = photoPath
        )

        val savedUser = userRepository.save(user)
        accountRecovery.requestVerification(savedUser.email)
        return Response(true, "User has been created. Check your email to verify the account before signing in.", savedUser.toResponse())
    }

    /**
     * UPDATE USER (without photo for now)
     */
    @Transactional
    fun update(id: Long, request: CreateUserRequest): Response {
        val user = userRepository.findByIdOrNull(id) ?: return Response(false, "User not found", null)

        user.username = request.username
        user.email = request.email
        user.firstName = request.firstName
        user.lastName = request.lastName

        if (!request.password.isNullOrBlank()) {
            user.password = passwordEncoder.encode(request.password)!!
        }

        val updatedUser = userRepository.save(user)
        return Response(true, "User has been updated", updatedUser.toResponse())
    }

    /**
     * GET USER BY HID
     */
    fun edit(id: String): Response {
        val user = userRepository.findByuserHid(id)
        return if (user != null) {
            Response(true, "User found", user.toResponse())
        } else {
            Response(false, "User not found", null)
        }
    }

    /**
     * GET ALL USERS
     */
    fun getAllUsers(): List<UserResponse> {
        return userRepository.findAll().map { it.toResponse() }
    }

    /**
     * ENABLE USER
     */
    @Transactional
    fun enabled(id: Long): Response {
        val user = userRepository.findByIdOrNull(id)
            ?: return Response(false, "The user is not found", null)

        user.enabled = true
        val savedUser = userRepository.save(user)
        return Response(true, "The user has been enabled", savedUser.toResponse())
    }

    /**
     * IMAGE VALIDATION
     */
    private fun validateImage(file: MultipartFile) {
        val allowedTypes = listOf("image/jpeg", "image/png", "image/webp")

        if (file.isEmpty) throw RuntimeException("Photo is empty")
        if (file.size > 5 * 1024 * 1024) throw RuntimeException("Max image size is 5MB")
        if (file.contentType !in allowedTypes) throw RuntimeException("Only JPG, PNG, WEBP allowed")
    }
}
