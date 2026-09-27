package com.example.gateway

import jakarta.persistence.*
import org.springframework.stereotype.Service
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

enum class WebhookDeliveryStatus { PENDING, DELIVERED, RETRYING, FAILED }
@Entity @Table(name="webhook_deliveries") class WebhookDelivery(@Id @GeneratedValue(strategy=GenerationType.UUID) var id:String?=null,@Column(nullable=false) var webhookId:String,@Column(nullable=false) var eventId:String,@Column(nullable=false) var eventType:String,@Enumerated(EnumType.STRING) @Column(nullable=false) var status:WebhookDeliveryStatus=WebhookDeliveryStatus.PENDING,var attempts:Int=0,var nextAttemptAt:Instant=Instant.now(),var lastHttpStatus:Int?=null,@Column(nullable=false) var createdAt:Instant=Instant.now())
interface WebhookDeliveryRepository:org.springframework.data.jpa.repository.JpaRepository<WebhookDelivery,String>
@Service class WebhookDeliveryService(private val deliveries:WebhookDeliveryRepository,private val webhooks:DeveloperWebhookRepository){ private val client=HttpClient.newHttpClient(); fun queue(webhookId:String,eventId:String,type:String)=deliveries.save(WebhookDelivery(webhookId=webhookId,eventId=eventId,eventType=type)); @Scheduled(fixedDelayString="\${gateway.webhooks.interval-ms:30000}") fun dispatch(){deliveries.findAll().filter{it.status in setOf(WebhookDeliveryStatus.PENDING,WebhookDeliveryStatus.RETRYING)&&!it.nextAttemptAt.isAfter(Instant.now())}.forEach{send(it)}} fun send(d:WebhookDelivery){val hook=webhooks.findById(d.webhookId).orElse(null)?:return;if(!hook.active||!hook.url.startsWith("https://")){retry(d.id!!);return};val body="{\"eventId\":\"${d.eventId}\",\"type\":\"${d.eventType}\",\"createdAt\":\"${d.createdAt}\"}";try{val request=HttpRequest.newBuilder(URI.create(hook.url)).header("Content-Type","application/json").header("X-Webhook-Id",d.eventId).header("X-Webhook-Signature",sign(hook.signingKeyReference,body)).POST(HttpRequest.BodyPublishers.ofString(body)).build();val response=client.send(request,HttpResponse.BodyHandlers.discarding());d.lastHttpStatus=response.statusCode();d.status=if(response.statusCode() in 200..299)WebhookDeliveryStatus.DELIVERED else WebhookDeliveryStatus.RETRYING;if(d.status==WebhookDeliveryStatus.RETRYING)retry(d.id!!,response.statusCode()) else deliveries.save(d)}catch(_:Exception){retry(d.id!!)}} fun retry(id:String,httpStatus:Int?=null):WebhookDelivery{val d=deliveries.findById(id).orElseThrow{IllegalArgumentException("Delivery not found")};d.attempts++;d.lastHttpStatus=httpStatus;d.status=if(d.attempts>=8) WebhookDeliveryStatus.FAILED else WebhookDeliveryStatus.RETRYING;d.nextAttemptAt=Instant.now().plusSeconds((1L shl minOf(d.attempts,10))*30);return deliveries.save(d)} private fun sign(key:String,body:String):String{val mac=Mac.getInstance("HmacSHA256");mac.init(SecretKeySpec(key.toByteArray(),"HmacSHA256"));return mac.doFinal(body.toByteArray()).joinToString(""){"%02x".format(it)}} }
@RestController @RequestMapping("/api/v1/developer/webhooks") class WebhookDeliveryController(private val service:WebhookDeliveryService){@PostMapping("/{id}/redeliver") fun redeliver(@PathVariable id:String)=service.retry(id)}
