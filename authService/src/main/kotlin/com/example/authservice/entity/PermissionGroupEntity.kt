package com.example.authservice.entity

import jakarta.persistence.*

@Entity
@Table(name = "permission_groups")
class PermissionGroupEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var name: String,
    @ManyToOne
    @JoinColumn(name = "client_id")
    var client: ClientEntity? = null

) {
    @OneToMany(mappedBy = "permissionGroup", cascade = [CascadeType.ALL], orphanRemoval = true)
    var permissions: MutableSet<PermissionEntity> = mutableSetOf()
}
