package com.example.gateway

import jakarta.persistence.*
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*

/** Versioned profile metadata. Exact field rules must be loaded from the bank's certified switch profile. */
@Entity @Table(name = "iso8583_profiles", uniqueConstraints = [UniqueConstraint(columnNames = ["profile_code", "version"])])
class IsoProfileEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "profile_code", nullable = false) var profileCode: String, @Column(nullable = false) var version: String, @Column(nullable = false) var transport: String = "TCP_TLS", @Column(nullable = false) var active: Boolean = false)
@Entity @Table(name = "iso8583_field_rules", uniqueConstraints = [UniqueConstraint(columnNames = ["profile_id", "field_number"])])
class IsoFieldRuleEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "profile_id", nullable = false) var profileId: String, @Column(name = "field_number", nullable = false) var fieldNumber: Int, @Column(nullable = false) var encoding: String, @Column(nullable = false) var lengthType: String, @Column(nullable = false) var masked: Boolean = true, var requiredFor: String? = null)
interface IsoProfileRepository : org.springframework.data.jpa.repository.JpaRepository<IsoProfileEntity, String>
interface IsoFieldRuleRepository : org.springframework.data.jpa.repository.JpaRepository<IsoFieldRuleEntity, String>
data class IsoProfileRequest(@field:NotBlank val profileCode: String, @field:NotBlank val version: String, val transport: String? = null)
data class IsoFieldRuleRequest(val fieldNumber: Int, @field:NotBlank val encoding: String, @field:NotBlank val lengthType: String, val masked: Boolean? = null, val requiredFor: String? = null)

@Service
class IsoProfileService(private val profiles: IsoProfileRepository, private val rules: IsoFieldRuleRepository) {
    fun create(request: IsoProfileRequest) = profiles.save(IsoProfileEntity(profileCode = request.profileCode, version = request.version, transport = request.transport?.takeIf { it.isNotBlank() } ?: "TCP_TLS"))
    fun addRule(profileId: String, request: IsoFieldRuleRequest): IsoFieldRuleEntity { require(profiles.existsById(profileId)) { "ISO profile not found" }; return rules.save(IsoFieldRuleEntity(profileId = profileId, fieldNumber = request.fieldNumber, encoding = request.encoding, lengthType = request.lengthType, masked = request.masked ?: true, requiredFor = request.requiredFor?.takeIf { it.isNotBlank() })) }
    fun all() = profiles.findAll().map { profile -> mapOf("profile" to profile, "fieldRules" to rules.findAll().filter { it.profileId == profile.id }) }
}

@RestController @RequestMapping("/api/v1/admin/iso-profiles")
class IsoProfileController(private val service: IsoProfileService) {
    @PostMapping fun create(@Valid @RequestBody request: IsoProfileRequest) = service.create(request)
    @PostMapping("/{profileId}/fields") fun rule(@PathVariable profileId: String, @Valid @RequestBody request: IsoFieldRuleRequest) = service.addRule(profileId, request)
    @GetMapping fun all() = service.all()
}
