package com.example.authservice.controller

import com.example.authservice.dto.response.Response
import com.example.authservice.dto.user.CreateUserRequest
import com.example.authservice.dto.user.UserResponse
import com.example.authservice.service.UserService
import jakarta.validation.Valid
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile

@RestController
@RequestMapping("/users")
class UserController(
    private val userService: UserService,
) {

    // CREATE USER WITH PHOTO
    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun createUser(
        @Valid @RequestPart("user") request: CreateUserRequest,
        @RequestPart("photo", required = false) photo: MultipartFile?
    ): Response {
        return userService.createUser(request, photo)
    }

    @GetMapping
    fun getAllUsers(): List<UserResponse> {
        return userService.getAllUsers()
    }

    @GetMapping("/{id}/edit")
    fun editUser(@PathVariable id: String): Response {
        return userService.edit(id)
    }

    @PutMapping("/{id}")
    fun updateUser(
        @PathVariable id: Long,
        @Valid @RequestBody request: CreateUserRequest
    ): Response {
        return userService.update(id, request)
    }

    @PatchMapping("/{id}/enable")
    fun enableUser(@PathVariable id: Long): Response {
        return userService.enabled(id)
    }
}
