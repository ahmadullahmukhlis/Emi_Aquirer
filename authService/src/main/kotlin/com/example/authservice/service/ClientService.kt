package com.example.authservice.service

import com.example.authservice.dto.client.ClientResponse
import com.example.authservice.dto.client.CreateClientRequest
import com.example.authservice.dto.client.toResponse
import com.example.authservice.dto.response.Response
import com.example.authservice.encryption.IdEncryption
import com.example.authservice.entity.ClientEntity
import com.example.authservice.repository.ClientRepository
import org.springframework.http.ResponseEntity
import org.springframework.stereotype.Service
import java.util.*

@Service
class ClientService(
    private val clientRespository: ClientRepository,
    private val idEncryption: IdEncryption
) {

    fun index(): List<ClientResponse> =
        clientRespository.findAll().map { it.toResponse() }

    fun show(id: String): Response {
        val client = clientRespository.findByClientId(id)
        return if (client == null) {
            Response(false, "Client not found", null)
        } else {
            Response(true, "Client found", client.toResponse())
        }
    }

    fun create(request: CreateClientRequest): Response {

        // 🔐 Ensure unique clientId
        var clientId: String
        do {
            clientId = idEncryption.generateUniqueEncryptedId()
        } while (clientRespository.findByClientId(clientId) != null)

        val publicKeyRaw = "public_${request.name}_${UUID.randomUUID()}"
        val privateKeyRaw = "private_${request.name}_${UUID.randomUUID()}"

        val client = ClientEntity(
            name = request.name,
            clientId = clientId,
            publicKey = idEncryption.encrypt(publicKeyRaw),
            privateKey = idEncryption.encrypt(privateKeyRaw)
        )

        clientRespository.save(client)

        return Response(
            status = true,
            message = "Client created successfully",
            data = client.toResponse()
        )
    }

    fun update(id: String, request: CreateClientRequest): Response {
        val client = clientRespository.findByClientId(id)
            ?: return Response(false, "Client not found", null)

        client.name = request.name
        clientRespository.save(client)

        return Response(true, "Client updated", client.toResponse())
    }
    fun loadwithUser(id: String): Response {
        val client = clientRespository.findByClientId(id);
        if (client == null) {
            return Response(false, "Client not found", null)
        }
        return Response(
            status = true,
            message = "Client  found",
            data = client.toResponse(true)
        )
    }
}
