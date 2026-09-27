package com.example.gateway

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import jakarta.persistence.*
import jakarta.validation.constraints.NotBlank
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.util.UUID

enum class WorkspaceRole { OWNER, ADMIN, DEVELOPER, ANALYST, FINANCE }
enum class WorkspaceMembershipStatus { INVITED, ACTIVE, REVOKED }

@Entity @Table(name = "workspace_memberships", uniqueConstraints = [UniqueConstraint(columnNames = ["organization_id", "subject"])])
class WorkspaceMembership(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Column(name = "organization_id", nullable = false) var organizationId: String,
    @Column(nullable = false) var subject: String,
    @Enumerated(EnumType.STRING) @Column(nullable = false) var role: WorkspaceRole,
    @Enumerated(EnumType.STRING) @Column(nullable = false) var status: WorkspaceMembershipStatus = WorkspaceMembershipStatus.INVITED,
    @Column(name = "invited_by") var invitedBy: String? = null,
    @Column(nullable = false) var createdAt: Instant = Instant.now()
)

interface WorkspaceMembershipRepository : org.springframework.data.jpa.repository.JpaRepository<WorkspaceMembership, String> {
    fun findByOrganizationId(organizationId: String): List<WorkspaceMembership>
    fun findByOrganizationIdAndSubject(organizationId: String, subject: String): WorkspaceMembership?
    fun findBySubjectAndStatus(subject: String, status: WorkspaceMembershipStatus): List<WorkspaceMembership>
}

data class WorkspaceRequest(@field:NotBlank val name: String)
data class WorkspaceInviteRequest(@field:NotBlank val subject: String, val role: WorkspaceRole = WorkspaceRole.DEVELOPER)
data class WorkspaceAppRequest(@field:NotBlank val name: String)

@Service
class PortalIdentity(@Value("${'$'}{gateway.portal.jwt-secret:}") private val secret: String) {
    fun subject(authorization: String?): String {
        require(authorization?.startsWith("Bearer ") == true) { "Portal authentication is required" }
        require(secret.length >= 32) { "Portal JWT validation is not configured" }
        return Jwts.parser().verifyWith(Keys.hmacShaKeyFor(secret.toByteArray())).build().parseSignedClaims(authorization.removePrefix("Bearer ")).payload.subject
    }
}

@Service
class WorkspaceService(
    private val identity: PortalIdentity,
    private val organizations: DeveloperOrganizationRepository,
    private val memberships: WorkspaceMembershipRepository,
    private val apps: DeveloperAppRepository,
    private val merchants: MerchantRepository,
    private val credentials: DeveloperCredentialRepository,
    private val webhooks: DeveloperWebhookRepository,
    private val logs: DeveloperApiLogRepository,
    private val payments: PaymentRepository
) {
    fun list(authorization: String?) = memberships.findBySubjectAndStatus(identity.subject(authorization), WorkspaceMembershipStatus.ACTIVE).mapNotNull { member -> organizations.findById(member.organizationId).orElse(null)?.let { mapOf("id" to it.id, "name" to it.name, "role" to member.role, "status" to it.status) } }
    fun create(authorization: String?, request: WorkspaceRequest): DeveloperOrganization {
        val subject = identity.subject(authorization)
        val organization = organizations.save(DeveloperOrganization(name = request.name.trim(), ownerSubject = subject, status = "ACTIVE"))
        memberships.save(WorkspaceMembership(organizationId = organization.id!!, subject = subject, role = WorkspaceRole.OWNER, status = WorkspaceMembershipStatus.ACTIVE, invitedBy = subject))
        return organization
    }
    fun invite(authorization: String?, id: String, request: WorkspaceInviteRequest): WorkspaceMembership {
        val actor = identity.subject(authorization); requireRole(id, actor, setOf(WorkspaceRole.OWNER, WorkspaceRole.ADMIN))
        val existing = memberships.findByOrganizationIdAndSubject(id, request.subject)
        if (existing != null) { existing.role = request.role; existing.status = WorkspaceMembershipStatus.INVITED; existing.invitedBy = actor; return memberships.save(existing) }
        return memberships.save(WorkspaceMembership(organizationId = id, subject = request.subject, role = request.role, invitedBy = actor))
    }
    fun accept(authorization: String?, id: String): WorkspaceMembership {
        val membership = memberships.findByOrganizationIdAndSubject(id, identity.subject(authorization)) ?: throw IllegalArgumentException("No invitation exists for this workspace")
        require(membership.status == WorkspaceMembershipStatus.INVITED) { "Invitation is not available" }
        membership.status = WorkspaceMembershipStatus.ACTIVE
        return memberships.save(membership)
    }
    fun members(authorization: String?, id: String): List<WorkspaceMembership> { requireRole(id, identity.subject(authorization), WorkspaceRole.entries.toSet()); return memberships.findByOrganizationId(id) }
    fun apps(authorization: String?, id: String): List<DeveloperApp> { requireRole(id, identity.subject(authorization), WorkspaceRole.entries.toSet()); return apps.findByOrganizationId(id) }
    fun createApp(authorization: String?, id: String, request: WorkspaceAppRequest): DeveloperApp { requireRole(id, identity.subject(authorization), setOf(WorkspaceRole.OWNER, WorkspaceRole.ADMIN, WorkspaceRole.DEVELOPER)); return apps.save(DeveloperApp(organizationId = id, name = request.name.trim())) }
    fun workspaceMerchants(authorization: String?, id: String): List<MerchantEntity> { requireRole(id, identity.subject(authorization), WorkspaceRole.entries.toSet()); return merchants.findAll().filter { it.workspaceId == id } }
    fun assignMerchant(authorization: String?, id: String, merchantId: String): MerchantEntity { requireRole(id, identity.subject(authorization), setOf(WorkspaceRole.OWNER, WorkspaceRole.ADMIN, WorkspaceRole.FINANCE)); val merchant = merchants.findByMerchantId(merchantId) ?: throw IllegalArgumentException("Merchant not found"); merchant.workspaceId = id; return merchants.save(merchant) }
    fun credentials(authorization: String?, workspaceId: String, appId: String) = scopedApp(workspaceId, appId, authorization, WorkspaceRole.entries.toSet()).let { credentials.findByAppId(it.id!!) }
    fun webhooks(authorization: String?, workspaceId: String, appId: String) = scopedApp(workspaceId, appId, authorization, WorkspaceRole.entries.toSet()).let { webhooks.findByAppId(it.id!!) }
    fun logs(authorization: String?, workspaceId: String, appId: String) = scopedApp(workspaceId, appId, authorization, WorkspaceRole.entries.toSet()).let { logs.findByAppIdOrderByCreatedAtDesc(it.id!!) }
    fun transactions(authorization: String?, workspaceId: String): List<Map<String, Any?>> {
        requireRole(workspaceId, identity.subject(authorization), WorkspaceRole.entries.toSet())
        val merchantIds = merchants.findAll().filter { it.workspaceId == workspaceId }.map { it.merchantId }.toSet()
        return merchantIds.flatMap { merchantId -> payments.findByMerchantId(merchantId) }
            .sortedByDescending { it.createdAt }
            .map { transaction ->
                mapOf(
                    "id" to transaction.id,
                    "merchantId" to transaction.merchantId,
                    "terminalId" to transaction.terminalId,
                    "operation" to transaction.operation,
                    "channel" to transaction.channel,
                    "amountMinor" to transaction.amountMinor,
                    "currency" to transaction.currency,
                    "status" to transaction.status,
                    "responseCode" to transaction.responseCode,
                    "createdAt" to transaction.createdAt
                )
            }
    }
    private fun scopedApp(workspaceId: String, appId: String, authorization: String?, allowed: Set<WorkspaceRole>): DeveloperApp { requireRole(workspaceId, identity.subject(authorization), allowed); val app = apps.findById(appId).orElseThrow { IllegalArgumentException("Application not found") }; require(app.organizationId == workspaceId) { "Application does not belong to workspace" }; return app }
    private fun requireRole(id: String, subject: String, allowed: Set<WorkspaceRole>) { val membership = memberships.findByOrganizationIdAndSubject(id, subject); require(membership != null && membership.status == WorkspaceMembershipStatus.ACTIVE && membership.role in allowed) { "Workspace access denied" } }
}

@RestController
@RequestMapping("/api/v1/portal/workspaces")
class PortalWorkspaceController(private val workspaces: WorkspaceService) {
    @GetMapping fun list(@RequestHeader("Authorization", required = false) authorization: String?) = workspaces.list(authorization)
    @PostMapping @ResponseStatus(HttpStatus.CREATED) fun create(@RequestHeader("Authorization", required = false) authorization: String?, @RequestBody request: WorkspaceRequest) = workspaces.create(authorization, request)
    @GetMapping("/{id}/members") fun members(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = workspaces.members(authorization, id)
    @PostMapping("/{id}/invites") @ResponseStatus(HttpStatus.CREATED) fun invite(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String, @RequestBody request: WorkspaceInviteRequest) = workspaces.invite(authorization, id, request)
    @PostMapping("/{id}/accept-invitation") fun accept(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = workspaces.accept(authorization, id)
    @GetMapping("/{id}/apps") fun apps(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = workspaces.apps(authorization, id)
    @PostMapping("/{id}/apps") @ResponseStatus(HttpStatus.CREATED) fun app(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String, @RequestBody request: WorkspaceAppRequest) = workspaces.createApp(authorization, id, request)
    @GetMapping("/{id}/merchants") fun merchants(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = workspaces.workspaceMerchants(authorization, id)
    @PostMapping("/{id}/merchants/{merchantId}") fun assignMerchant(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String, @PathVariable merchantId: String) = workspaces.assignMerchant(authorization, id, merchantId)
    @GetMapping("/{workspaceId}/apps/{appId}/credentials") fun credentials(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable workspaceId: String, @PathVariable appId: String) = workspaces.credentials(authorization, workspaceId, appId)
    @GetMapping("/{workspaceId}/apps/{appId}/webhooks") fun webhooks(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable workspaceId: String, @PathVariable appId: String) = workspaces.webhooks(authorization, workspaceId, appId)
    @GetMapping("/{workspaceId}/apps/{appId}/logs") fun logs(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable workspaceId: String, @PathVariable appId: String) = workspaces.logs(authorization, workspaceId, appId)
    @GetMapping("/{id}/transactions") fun transactions(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = workspaces.transactions(authorization, id)
}
