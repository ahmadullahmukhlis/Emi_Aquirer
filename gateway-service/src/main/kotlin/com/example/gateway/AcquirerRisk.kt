package com.example.gateway

import jakarta.persistence.*
import org.springframework.stereotype.Service

@Entity @Table(name="acquirer_limit_rules") class AcquirerLimitRule(@Id @GeneratedValue(strategy=GenerationType.UUID) var id:String?=null,@Column(nullable=false) var scopeType:String,@Column(nullable=false) var scopeId:String,@Column(nullable=false) var transactionType:String,@Column(nullable=false) var maximumAmountMinor:Long,@Column(nullable=false) var enabled:Boolean=true)
interface AcquirerLimitRuleRepository:org.springframework.data.jpa.repository.JpaRepository<AcquirerLimitRule,String>
@Service class AcquirerRiskService(private val merchants:MerchantRepository,private val terminals:ManagedTerminalRepository,private val limits:AcquirerLimitRuleRepository){
 fun validateEstate(channel:PaymentChannel,request:PaymentRequest){require(merchants.findByMerchantId(request.merchantId)?.status==EntityStatus.ACTIVE){"Merchant is not active"};if(channel==PaymentChannel.POS){val terminal=terminals.findByTerminalId(request.terminalId!!);require(terminal?.status==TerminalLifecycle.ACTIVE&&terminal.merchantId==request.merchantId){"Terminal is not active for merchant"}}}
 fun validateLimit(operation:PaymentOperation,request:PaymentRequest){val amount=request.amountMinor?:return;limits.findAll().filter{it.enabled&&(it.scopeId==request.merchantId||it.scopeId==request.terminalId)&&it.transactionType==operation.name}.forEach{require(amount<=it.maximumAmountMinor){"Configured acquirer limit exceeded"}}}
}
