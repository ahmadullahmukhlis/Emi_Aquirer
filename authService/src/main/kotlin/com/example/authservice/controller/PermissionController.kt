package com.example.authservice.controller

import com.example.authservice.dto.permission.PermissionRequest
import com.example.authservice.dto.response.Response
import com.example.authservice.service.PermissionService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/permissions")
class PermissionController(private val permissionService: PermissionService) {

    @PostMapping
    fun create(@Valid @RequestBody request: PermissionRequest): ResponseEntity<Response> {
        val res = permissionService.createPermission(request)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.badRequest().body(res)
    }

    @PutMapping("/{id}")
    fun update(@PathVariable id: Long, @Valid @RequestBody request: PermissionRequest): ResponseEntity<Response> {
        val res = permissionService.update(id, request)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }

    @GetMapping
    fun getAll(): ResponseEntity<List<Any>> = ResponseEntity.ok(permissionService.getAll())

    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<Response> {
        val res = permissionService.getById(id)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<Response> {
        val res = permissionService.delete(id)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }
}
