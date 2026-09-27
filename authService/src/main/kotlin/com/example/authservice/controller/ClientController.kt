package com.example.authservice.controller

import com.example.authservice.dto.client.CreateClientRequest
import com.example.authservice.dto.response.Response
import com.example.authservice.service.ClientService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/client")
class ClientController(
    private val clientService: ClientService
) {

    // Get all clients
    @GetMapping
    fun getAllClients(): ResponseEntity<List<Any>> =
        ResponseEntity.ok(clientService.index())

    // Get client by clientId (query param)
    @GetMapping("/by-id")
    fun getClientById(@RequestParam id: String): ResponseEntity<Response> =
        ResponseEntity.ok(clientService.show(id ))

    // Create new client
    @PostMapping
    fun createClient(@RequestBody request: CreateClientRequest): ResponseEntity<Response> =
        ResponseEntity.ok(clientService.create(request))

    // Update existing client (query param)
    @PutMapping("/by-id")
    fun updateClient(
        @RequestParam id: String,
        @RequestBody request: CreateClientRequest
    ): ResponseEntity<Response> =
        ResponseEntity.ok(clientService.update(id, request))

    @GetMapping("/by_client/{id}/users")
    fun withUser(@PathVariable id: String): ResponseEntity<Response> {
        val response = clientService.loadwithUser(id, ) // load with users
        return ResponseEntity.ok(response)
    }

}


