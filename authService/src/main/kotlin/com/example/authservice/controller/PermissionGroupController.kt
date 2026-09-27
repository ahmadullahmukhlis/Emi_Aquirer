package com.example.authservice.controller

import com.example.authservice.dto.permissiongroup.PermissionGroupRequest
import com.example.authservice.dto.response.Response
import com.example.authservice.service.PermissionGroupService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/permission-groups")
class PermissionGroupController(
    private val permissionGroupService: PermissionGroupService
) {

    @PostMapping
    fun create(@Valid @RequestBody request: PermissionGroupRequest): ResponseEntity<Response> {
        val result = permissionGroupService.createPermissionGroup(request)
        return if (result.status) ResponseEntity.ok(result) else ResponseEntity.badRequest().body(result)
    }

    @PutMapping("/{id}")
    fun update(
        @PathVariable id: Long,
        @Valid @RequestBody request: PermissionGroupRequest
    ): ResponseEntity<Response> {
        val result = permissionGroupService.update(id, request)
        return if (result.status) ResponseEntity.ok(result) else ResponseEntity.status(404).body(result)
    }

    @GetMapping
    fun getAll(): ResponseEntity<List<Any>> = ResponseEntity.ok(permissionGroupService.getAll())

    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<Response> {
        val result = permissionGroupService.getById(id)
        return if (result.status) ResponseEntity.ok(result) else ResponseEntity.status(404).body(result)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<Response> {
        val result = permissionGroupService.delete(id)
        return if (result.status) ResponseEntity.ok(result) else ResponseEntity.status(404).body(result)
    }
}
