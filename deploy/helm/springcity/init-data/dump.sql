-- ============================================================================
-- Dump initial de la base de données pour environnements éphémères
-- ============================================================================
-- Ce fichier sera utilisé pour initialiser les bases de données des PRs
-- Mettre à jour avec: ./scripts/dump-prod-db.sh
-- ============================================================================

-- Créer la table cities si elle n'existe pas
CREATE TABLE IF NOT EXISTS city (
    id BIGSERIAL PRIMARY KEY,
    department_code VARCHAR(3) NOT NULL,
    insee_code VARCHAR(5) NOT NULL,
    zip_code VARCHAR(5) NOT NULL,
    name VARCHAR(255) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL
);

-- Données d'exemple pour les tests
INSERT INTO city (department_code, insee_code, zip_code, name, lat, lon) VALUES
('34', '34172', '34000', 'Montpellier', 43.6108, 3.8767),
('75', '75056', '75001', 'Paris', 48.8566, 2.3522),
('13', '13055', '13000', 'Marseille', 43.2965, 5.3698),
('69', '69123', '69000', 'Lyon', 45.7640, 4.8357),
('31', '31555', '31000', 'Toulouse', 43.6047, 1.4442)
ON CONFLICT DO NOTHING;
