package com.example.authservice.controller

import com.example.authservice.dto.RoleGroup.RoleGroupRequest
import com.example.authservice.dto.response.Response
import com.example.authservice.service.RoleGroupService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/role-groups")
class RoleGroupController(
    private val roleGroupService: RoleGroupService
) {

    /**
     * CREATE NEW ROLE GROUP
     */
    @PostMapping
    fun create(@Valid @RequestBody request: RoleGroupRequest): ResponseEntity<Response> {
        val result = roleGroupService.createRoleGroup(request)
        return if (result.status) ResponseEntity.ok(result)
        else ResponseEntity.badRequest().body(result)
    }

    /**
     * UPDATE EXISTING ROLE GROUP
     */
    @PutMapping("/{id}")
    fun update(
        @PathVariable id: Long,
        @Valid @RequestBody request: RoleGroupRequest
    ): ResponseEntity<Response> {
        val result = roleGroupService.updateRoleGroup(id, request)
        return if (result.status) ResponseEntity.ok(result)
        else ResponseEntity.status(404).body(result)
    }

    /**
     * GET ALL ROLE GROUPS
     */
    @GetMapping
    fun getAll(): ResponseEntity<List<Any>> {
        return ResponseEntity.ok(roleGroupService.getAllRoleGroups())
    }

    /**
     * GET ROLE GROUP BY ID
     */
    @GetMapping("/{id}")
    fun getById(@PathVariable id: Long): ResponseEntity<Response> {
        val result = roleGroupService.getById(id)
        return if (result.status) ResponseEntity.ok(result)
        else ResponseEntity.status(404).body(result)
    }

    /**
     * DELETE ROLE GROUP
     */
    @DeleteMapping("/{id}")
    fun delete(@PathVariable id: Long): ResponseEntity<Response> {
        val result = roleGroupService.delete(id)
        return if (result.status) ResponseEntity.ok(result)
        else ResponseEntity.status(404).body(result)
    }
}
