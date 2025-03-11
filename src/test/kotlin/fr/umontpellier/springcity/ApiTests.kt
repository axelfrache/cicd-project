package fr.umontpellier.springcity

import com.ninjasquad.springmockk.MockkBean
import fr.umontpellier.springcity.model.City
import fr.umontpellier.springcity.repository.CityRepository
import io.mockk.every
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest
class ApiTests(
    @Autowired val mockMvc: MockMvc,
) {
    @MockkBean
    private lateinit var cityRepository: CityRepository

    @Test
    fun testHealthCheck() {
        mockMvc
            .perform(get("/_health"))
            .andExpect(status().`is`(204))
    }

    @Test
    fun testGetAllCities() {
        every { cityRepository.findAll() } returns
            listOf(
                City(1, "31", "feur", "31790", "Saint-Sauveur", 45.610769, 2.876716),
            )
        mockMvc
            .perform(get("/city"))
            .andExpect(status().`is`(200))
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }

    @Test
    fun testPostCity() {
        every {
            cityRepository.save(any())
        } returns
            City(id = 1, departmentCode = "31", inseeCode = "feur", zipCode = "31790", name = "Saint-Sauveur", lat = 45.610769, lon = 2.876716)

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
            ).andExpect(status().`is`(201))
            .andExpect(content().contentType(MediaType.APPLICATION_JSON))
    }
}
