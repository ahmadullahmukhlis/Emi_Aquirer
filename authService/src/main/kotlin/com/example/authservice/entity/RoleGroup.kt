package com.example.authservice.entity

import jakarta.persistence.*

@Entity
@Table(name = "role_groups")
class RoleGroupEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var name: String ,
    @ManyToOne
    @JoinColumn(name = "client_id")
    var client: ClientEntity? = null

) {
    @OneToMany(mappedBy = "roleGroup", cascade = [CascadeType.ALL], orphanRemoval = true)
    var roles: MutableSet<RoleEntity> = mutableSetOf()
}
