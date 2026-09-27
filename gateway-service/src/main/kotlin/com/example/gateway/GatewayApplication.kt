package com.example.gateway

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.scheduling.annotation.EnableScheduling
import org.springframework.boot.runApplication

@SpringBootApplication
@EnableScheduling
class GatewayApplication
fun main(args: Array<String>) = runApplication<GatewayApplication>(*args)
