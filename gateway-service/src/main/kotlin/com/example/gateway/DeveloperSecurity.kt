package com.example.gateway

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerInterceptor

@Component class DeveloperSecurity(private val auth:DeveloperAuthService,private val certificates:DeveloperCertificateRepository) : HandlerInterceptor {
 override fun preHandle(request:HttpServletRequest,response:HttpServletResponse,handler:Any):Boolean { if(request.requestURI.endsWith("/oauth/token")) return true; val token=request.getHeader("Authorization")?.removePrefix("Bearer ")?:run{response.sendError(401,"Developer token required");return false};val appId=auth.validate(token)?:run{response.sendError(401,"Developer token invalid");return false};val thumbprint=request.getHeader("X-Client-Certificate-Thumbprint");if(!thumbprint.isNullOrBlank()&&certificates.findByAppId(appId).none{it.thumbprint==thumbprint}){response.sendError(403,"mTLS certificate not registered");return false};return true }
}
