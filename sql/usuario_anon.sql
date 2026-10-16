-- =================================================================
-- PARTE D: ANONIMIZACIÓN DETERMINISTA Y EQUIVALENCIA (FOOD STORE)
-- =================================================================

-- 1. Construcción de la tabla usuario_anon (Punto D.1)
DROP TABLE IF EXISTS usuario_anon CASCADE;
CREATE TABLE usuario_anon (
    id_usuario INT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido VARCHAR(80) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    telefono VARCHAR(30),
    direccion VARCHAR(150),
    password_hash TEXT NOT NULL,
    rol VARCHAR(30) NOT NULL,
    fecha_alta DATE NOT NULL,
    activo BOOLEAN NOT NULL
);

-- 2. Poblado con datos sintéticos deterministas a partir de usuario
-- Se enmascaran PII y credenciales, preservando intactos rol, fecha_alta y activo para análisis estadístico
INSERT INTO usuario_anon (
    id_usuario, nombre, apellido, email, telefono, direccion, password_hash, rol, fecha_alta, activo
)
SELECT 
    id_usuario,
    'Nombre_' || lpad(id_usuario::text, 3, '0') AS nombre,
    'Apellido_' || substr(md5(id_usuario::text), 1, 6) AS apellido,
    'usr_' || lpad(id_usuario::text, 3, '0') || '@anon.foodstore.local' AS email,
    '000-0000' || lpad(id_usuario::text, 3, '0') AS telefono,
    'Calle Ficticia ' || (id_usuario * 100) || ', Zona Anonima' AS direccion,
    'REDACTED_HASH_' || md5('salt_anon_' || id_usuario::text) AS password_hash,
    rol,
    fecha_alta,
    activo
FROM usuario;

-- Otorgamos permiso de lectura sobre la tabla anonimizada al rol de reportes
GRANT SELECT ON usuario_anon TO rol_reportes;

-- =================================================================
-- 3. Consultas de agregación equivalentes (Puntos D.2 y D.3)
-- =================================================================

-- 3.a Consulta sobre tabla anonimizada (usuario_anon)
SELECT 
    TO_CHAR(DATE_TRUNC('month', fecha_alta), 'YYYY-MM') AS mes_alta,
    rol,
    COUNT(*) AS total_usuarios,
    SUM(CASE WHEN activo THEN 1 ELSE 0 END) AS usuarios_activos
FROM usuario_anon
GROUP BY DATE_TRUNC('month', fecha_alta), rol
ORDER BY mes_alta, rol;

-- 3.b Consulta equivalente sobre tabla real (usuario)
SELECT 
    TO_CHAR(DATE_TRUNC('month', fecha_alta), 'YYYY-MM') AS mes_alta,
    rol,
    COUNT(*) AS total_usuarios,
    SUM(CASE WHEN activo THEN 1 ELSE 0 END) AS usuarios_activos
FROM usuario
GROUP BY DATE_TRUNC('month', fecha_alta), rol
ORDER BY mes_alta, rol;