package com.example.gateway

/** Certified SmartVista transport boundary. The simulator and TCP adapter implement this contract; business services never construct ISO bitmaps. */
interface ApsConnector {
    fun authorize(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest, stan: String): Pair<PaymentStatus, Map<String, String>>
}

class LocalApsConnector(private val delegate: LocalIso8583Switch) : ApsConnector {
    override fun authorize(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest, stan: String) = delegate.execute(channel, operation, request, stan)
}
