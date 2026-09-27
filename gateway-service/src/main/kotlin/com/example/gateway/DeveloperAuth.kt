package com.example.gateway

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.util.UUID

data class DeveloperTokenRequest(val clientId:String,val clientSecret:String,val scope:String="")
data class DeveloperTokenResponse(val accessToken:String,val tokenType:String="Bearer",val expiresIn:Int=900,val scope:String)
@Service class DeveloperAuthService(private val credentials:DeveloperCredentialRepository){ private val encoder=BCryptPasswordEncoder(); private val tokens=mutableMapOf<String,Pair<String,Instant>>()
 fun issue(r:DeveloperTokenRequest):DeveloperTokenResponse{val c=credentials.findAll().firstOrNull{it.clientId==r.clientId&&!it.revoked}?:throw IllegalArgumentException("Invalid developer client");require(encoder.matches(r.clientSecret,c.secretReference)){"Invalid developer client"};val token="dpat_"+UUID.randomUUID().toString().replace("-","");tokens[token]=c.appId to Instant.now().plusSeconds(900);return DeveloperTokenResponse(token,scope=r.scope)}
 fun validate(token:String)=tokens[token]?.takeIf{Instant.now().isBefore(it.second)}?.first }
@RestController @RequestMapping("/api/v1/developer/oauth") class DeveloperAuthController(private val auth:DeveloperAuthService){@PostMapping("/token") fun token(@RequestBody r:DeveloperTokenRequest)=auth.issue(r)}
