package fr.umontpellier.springcity.dto

import com.fasterxml.jackson.annotation.JsonProperty
import io.swagger.v3.oas.annotations.media.Schema

@Schema(description = "Requête de création d'une ville")
data class CityRequest(
    @JsonProperty("department_code")
    @Schema(description = "Code du département", example = "34")
    val departmentCode: String,
    
    @JsonProperty("insee_code")
    @Schema(description = "Code INSEE de la ville", example = "34172")
    val inseeCode: String?,
    
    @JsonProperty("zip_code")
    @Schema(description = "Code postal de la ville", example = "34000")
    val zipCode: String?,
    
    @Schema(description = "Nom de la ville", example = "Montpellier")
    val name: String,
    
    @Schema(description = "Latitude de la ville", example = "43.610769")
    val lat: Double,
    
    @Schema(description = "Longitude de la ville", example = "3.876716")
    val lon: Double
) 