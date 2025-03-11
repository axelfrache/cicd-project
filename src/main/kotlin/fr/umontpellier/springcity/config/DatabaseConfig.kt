package fr.umontpellier.springcity.config

import org.springframework.beans.factory.InitializingBean
import org.springframework.context.annotation.Configuration
import org.springframework.core.env.Environment

@Configuration
class DatabaseConfig(private val env: Environment) : InitializingBean {

    override fun afterPropertiesSet() {
        checkRequiredProperty("CITY_API_DB_URL")
        checkRequiredProperty("CITY_API_DB_USER")
        checkRequiredProperty("CITY_API_DB_PWD")
    }

    private fun checkRequiredProperty(property: String) {
        if (env.getProperty(property).isNullOrBlank()) {
            throw IllegalStateException("$property must be set")
        }
    }
} 