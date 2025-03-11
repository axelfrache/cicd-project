CREATE TABLE city (
    id BIGSERIAL PRIMARY KEY,
    department_code VARCHAR(3) NOT NULL,
    insee_code VARCHAR(5),
    zip_code VARCHAR(5),
    name VARCHAR(100) NOT NULL,
    lat FLOAT NOT NULL,
    lon FLOAT NOT NULL
);

INSERT INTO city (department_code, insee_code, zip_code, name, lat, lon) VALUES
    ('01', '01001', '01400', 'L''Abergement-Clémenciat', 46.15678199203189, 4.92469920318725),
    ('01', '01002', '01640', 'L''Abergement-de-Varey', 46.01008562499999, 5.42875916666667),
    ('01', '01004', '01500', 'Ambérieu-en-Bugey', 45.95840939226519, 5.3759920441989);