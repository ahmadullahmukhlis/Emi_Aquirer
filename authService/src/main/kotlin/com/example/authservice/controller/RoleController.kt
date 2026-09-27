package com.example.authservice.controller

import com.example.authservice.dto.RoleGroup.RoleRequest
import com.example.authservice.dto.response.Response
import com.example.authservice.service.RoleService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/roles")
class RoleController(private val roleService: RoleService) {

    @PostMapping
    fun create(@Valid @RequestBody request: RoleRequest): ResponseEntity<Response> {
        val res = roleService.createRole(request)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.badRequest().body(res)
    }

    @PutMapping("/{id}")
    fun update(@PathVariable id: Long, @Valid @RequestBody request: RoleRequest): ResponseEntity<Response> {
        val res = roleService.updateRole(id, request)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }

    @GetMapping
    fun getAll(): ResponseEntity<List<Any>> = ResponseEntity.ok(roleService.getAllRoles())

    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<Response> {
        val res = roleService.getById(id)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }

    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<Response> {
        val res = roleService.delete(id)
        return if (res.status) ResponseEntity.ok(res) else ResponseEntity.status(404).body(res)
    }
}
