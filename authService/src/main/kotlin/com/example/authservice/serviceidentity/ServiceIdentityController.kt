package com.example.authservice.serviceidentity

import jakarta.validation.Valid
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/service-keys")
class ServiceIdentityController(private val service: ServiceIdentityService) {
    @PostMapping @org.springframework.web.bind.annotation.ResponseStatus(HttpStatus.CREATED)
    fun create(@Valid @RequestBody request: CreateServiceKeyRequest) = service.create(request)
    @GetMapping fun list() = service.list()
    @DeleteMapping("/{id}") fun revoke(@PathVariable id: String) = service.revoke(id)
}
