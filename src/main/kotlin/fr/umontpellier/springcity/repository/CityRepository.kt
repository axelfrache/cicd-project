package fr.umontpellier.springcity.repository

import fr.umontpellier.springcity.model.City
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface CityRepository : JpaRepository<City, Long>
