package fr.umontpellier.springcity

import com.ninjasquad.springmockk.MockkBean
import fr.umontpellier.springcity.controller.CityController
import fr.umontpellier.springcity.model.City
import fr.umontpellier.springcity.repository.CityRepository
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import io.mockk.every
import io.mockk.slot
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultHandlers
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest(CityController::class)
@Import(ApiTests.TestConfig::class)
class ApiTests {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockkBean
    private lateinit var cityRepository: CityRepository

    class TestConfig {
        @Bean
        fun meterRegistry(): MeterRegistry = SimpleMeterRegistry()
    }

    @Test
    fun testHealthCheck() {
        mockMvc
            .perform(get("/_health"))
            .andDo(MockMvcResultHandlers.print())
            .andExpect(status().isNoContent())
    }

    @Test
    fun testGetAllCities() {
        // Configurer le mock pour retourner une liste de villes
        every { cityRepository.findAll() } returns
            listOf(
                City(
                    id = 1,
                    departmentCode = "31",
                    inseeCode = "feur",
                    zipCode = "31790",
                    name = "Saint-Sauveur",
                    lat = 45.610769,
                    lon = 2.876716,
                ),
            )

        mockMvc
            .perform(get("/city"))
            .andDo(MockMvcResultHandlers.print())
            .andExpect(status().isOk())
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }

    @Test
    fun testPostCity() {
        // Capturer l'objet City passé à save()
        val citySlot = slot<City>()

        // Configurer le mock pour retourner une ville avec ID
        every { cityRepository.save(capture(citySlot)) } answers {
            City(
                id = 1,
                departmentCode = citySlot.captured.departmentCode,
                inseeCode = citySlot.captured.inseeCode,
                zipCode = citySlot.captured.zipCode,
                name = citySlot.captured.name,
                lat = citySlot.captured.lat,
                lon = citySlot.captured.lon,
            )
        }

        mockMvc
            .perform(
                post("/city")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(
                        """
                        {
                            "department_code": "31",
                            "insee_code": "feur",
                            "zip_code": "31790",
                            "name": "Saint-Sauveur",
                            "lat": 45.610769,
                            "lon": 2.876716
                        }
                        """.trimIndent(),
                    ),
            ).andDo(MockMvcResultHandlers.print())
            .andExpect(status().isCreated())
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }
}
