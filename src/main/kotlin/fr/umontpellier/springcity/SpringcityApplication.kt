package fr.umontpellier.springcity

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class SpringcityApplication

fun main(args: Array<String>) {
    runApplication<SpringcityApplication>(*args)
}
