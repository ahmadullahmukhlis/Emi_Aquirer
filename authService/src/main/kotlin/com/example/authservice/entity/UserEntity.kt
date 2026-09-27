package com.example.authservice.entity

import com.example.authservice.listner.UserEncryptListener
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class, UserEncryptListener::class)
class UserEntity(

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(unique = true, nullable = false)
    var username: String,

    @Column(name = "first_name", nullable = true)
    var firstName: String? = null,

    @Column(name = "last_name", nullable = true)
    var lastName: String? = null,


    @Column(unique = true, nullable = false)
    var email: String,

    @Column(name = "photo",nullable = true)
    var Photo: String?=null,

    @Column(nullable = false)
    var password: String,

    @Column(nullable = false)
    var enabled: Boolean = true,

    @Column(name = "email_verified", nullable = false)
    var emailVerified: Boolean = false,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime? = null,

    @LastModifiedDate
    @Column(name = "updated_at")
    var updatedAt: LocalDateTime? = null ,

    @Column(name = "user_hid", nullable = false, unique = true, length = 512)
    var userHid: String = "",

    @ManyToOne
    @JoinColumn(name = "client_id")
    var client: ClientEntity? = null

) {

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "users_roles",
        joinColumns = [JoinColumn(name = "user_id")],
        inverseJoinColumns = [JoinColumn(name = "role_id")]
    )
    var roles: MutableSet<RoleEntity> = mutableSetOf()
}
