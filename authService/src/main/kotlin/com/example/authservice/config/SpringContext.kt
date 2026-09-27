package com.example.authservice.config

import org.springframework.context.ApplicationContext
import org.springframework.stereotype.Component
import kotlin.reflect.KClass

@Component
class SpringContext(context: ApplicationContext) {

    companion object {
        lateinit var context: ApplicationContext

        // Use KClass to be Kotlin friendly
        fun <T : Any> getBean(clazz: KClass<T>): T {
            return context.getBean(clazz.java)
        }
    }

    init {
        Companion.context = context
    }
}
