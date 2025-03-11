package fr.umontpellier.springcity.controller

import fr.umontpellier.springcity.dto.CityRequest
import fr.umontpellier.springcity.model.City
import fr.umontpellier.springcity.repository.CityRepository
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.responses.ApiResponse
import io.swagger.v3.oas.annotations.responses.ApiResponses
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@Tag(name = "City API", description = "API pour gérer les villes")
class CityController(private val cityRepository: CityRepository) {

    @Operation(
        summary = "Créer une nouvelle ville",
        description = "Crée une nouvelle ville avec les informations fournies"
    )
    @ApiResponses(value = [
        ApiResponse(responseCode = "201", description = "Ville créée avec succès"),
        ApiResponse(responseCode = "400", description = "Requête invalide")
    ])
    @PostMapping("/city")
    fun createCity(@RequestBody cityRequest: CityRequest): ResponseEntity<City> {
        val city = City(
            id = null,
            departmentCode = cityRequest.departmentCode,
            inseeCode = cityRequest.inseeCode,
            zipCode = cityRequest.zipCode,
            name = cityRequest.name,
            lat = cityRequest.lat,
            lon = cityRequest.lon
        )
        val savedCity = cityRepository.save(city)
        return ResponseEntity(savedCity, HttpStatus.CREATED)
    }

    @Operation(
        summary = "Obtenir toutes les villes",
        description = "Récupère la liste de toutes les villes enregistrées"
    )
    @ApiResponse(responseCode = "200", description = "Liste des villes récupérée avec succès")
    @GetMapping("/city")
    fun getAllCities(): ResponseEntity<List<City>> {
        return ResponseEntity(cityRepository.findAll(), HttpStatus.OK)
    }

    @Operation(
        summary = "Vérifier l'état de l'API",
        description = "Endpoint de santé pour vérifier si l'API est opérationnelle"
    )
    @ApiResponse(responseCode = "204", description = "API opérationnelle")
    @GetMapping("/_health")
    fun healthCheck(): ResponseEntity<Void> {
        return ResponseEntity(HttpStatus.NO_CONTENT)
    }
} 