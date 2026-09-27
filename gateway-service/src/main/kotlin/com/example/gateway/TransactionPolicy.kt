package com.example.gateway

import org.springframework.stereotype.Service

/** Acquirer policy defaults from the APS blueprint. Certified OTP/PIN/EMV details are injected by the channel/HSM profile, never collected here. */
@Service class TransactionPolicy {
    private val informationOnly = setOf(PaymentOperation.BALANCE_INQUIRY, PaymentOperation.PAYMENT_INFO, PaymentOperation.CARD_TITLE_FETCH)
    fun validate(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest) {
        require(request.currency.length == 3) { "ISO currency is required" }
        require(channel != PaymentChannel.POS || !request.terminalId.isNullOrBlank()) { "terminalId is required for POS" }
        if (operation !in informationOnly) require((request.amountMinor ?: 0) > 0) { "A positive amount is required" }
        if (operation == PaymentOperation.REVERSAL) require(!request.originalTransactionId.isNullOrBlank()) { "originalTransactionId is required for reversal" }
        if (operation == PaymentOperation.CASH_OUT) require(channel == PaymentChannel.POS) { "Cash out requires an approved agent/POS terminal" }
        if (operation == PaymentOperation.CASH_IN) require(channel == PaymentChannel.POS) { "Cash in requires an approved agent/POS terminal" }
    }
    fun requiresRecovery(operation: PaymentOperation) = operation !in informationOnly
}
