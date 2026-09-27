package com.example.gateway

import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.*

/** Integration point for authService JWT/mTLS principal validation. Never trust merchant or terminal IDs supplied by a caller alone. */
@Component class GatewayAuthorization {
    fun requireScope(scope: String, suppliedScopes: String?) { val scopes = suppliedScopes?.split(' ')?.toSet() ?: emptySet(); require(scope in scopes || "gateway.admin" in scopes) { "Missing required scope: $scope" } }
    fun requireEstate(principalMerchantId: String?, requestedMerchantId: String) { require(principalMerchantId == null || principalMerchantId == requestedMerchantId) { "Merchant estate access denied" } }
}
@RestControllerAdvice class GatewayAuthorizationErrors { @ExceptionHandler(SecurityException::class) @ResponseStatus(HttpStatus.FORBIDDEN) fun forbidden(ex: SecurityException)=mapOf("message" to (ex.message ?: "Forbidden")) }
