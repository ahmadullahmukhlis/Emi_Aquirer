package com.example.authservice.entity

import jakarta.persistence.*

@Entity
@Table(name = "permissions")
class PermissionEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    // Label or description — not necessarily unique
    @Column(nullable = false)
    var name: String,

    // Unique permission string used in security checks
    @Column(unique = true, nullable = false)
    var permission: String,

    @ManyToOne
@JoinColumn(name = "permission_group_id")
var permissionGroup: PermissionGroupEntity? = null
) {
    @ManyToMany(mappedBy = "permissions")
    var roles: MutableSet<RoleEntity> = mutableSetOf()
}
