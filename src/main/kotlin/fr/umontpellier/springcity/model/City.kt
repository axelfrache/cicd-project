package fr.umontpellier.springcity.model

import com.fasterxml.jackson.annotation.JsonProperty
import io.swagger.v3.oas.annotations.media.Schema
import jakarta.persistence.*

@Entity
@Table(name = "city")
@Schema(description = "Représente une ville avec ses informations géographiques")
data class City(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Schema(description = "Identifiant unique de la ville", example = "1")
    val id: Long? = null,
    @JsonProperty("department_code")
    @Column(name = "department_code", nullable = false)
    @Schema(description = "Code du département", example = "34")
    val departmentCode: String,
    @JsonProperty("insee_code")
    @Column(name = "insee_code")
    @Schema(description = "Code INSEE de la ville", example = "34172")
    val inseeCode: String?,
    @JsonProperty("zip_code")
    @Column(name = "zip_code")
    @Schema(description = "Code postal de la ville", example = "34000")
    val zipCode: String?,
    @Column(nullable = false)
    @Schema(description = "Nom de la ville", example = "Montpellier")
    val name: String,
    @Column(nullable = false)
    @Schema(description = "Latitude de la ville", example = "43.610769")
    val lat: Double,
    @Column(nullable = false)
    @Schema(description = "Longitude de la ville", example = "3.876716")
    val lon: Double,
)
