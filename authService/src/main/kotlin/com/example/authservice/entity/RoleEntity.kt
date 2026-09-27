package com.example.authservice.entity

import jakarta.persistence.*

@Entity
@Table(name = "roles")
class RoleEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var name: String,
    @ManyToOne
    @JoinColumn(name = "role_group_id")
    var roleGroup: RoleGroupEntity? = null


) {



    // Inverse side of User ⇄ Role
    @ManyToMany(mappedBy = "roles")
    var users: MutableSet<UserEntity> = mutableSetOf()

    // Owning side of Role ⇄ Permission
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "roles_permissions",
        joinColumns = [JoinColumn(name = "role_id")],
        inverseJoinColumns = [JoinColumn(name = "permission_id")]
    )
    var permissions: MutableSet<PermissionEntity> = mutableSetOf()
}
