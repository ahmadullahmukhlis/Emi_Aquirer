package com.example.authservice.entity

import jakarta.persistence.*

@Entity
@Table(name = "clients")
class ClientEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var name: String,

    @Column(name = "client_hid", nullable = false, unique = true, length = 512)
    var clientId: String = "",

    @Column(nullable = false, columnDefinition = "TEXT")
    var publicKey: String = "",

    @Column(nullable = false, columnDefinition = "TEXT")
    var privateKey: String = "",

    @OneToMany(mappedBy = "client", fetch = FetchType.LAZY)
    var users: List<UserEntity> = emptyList()
)
