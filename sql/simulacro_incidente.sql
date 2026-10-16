-- =================================================================
-- PARTE C: LABORATORIO - SIMULACRO DE INCIDENTE (FOOD STORE)
-- =================================================================

-- Aseguramos registro completo en el log para capturar el incidente
SELECT set_config('log_statement', 'all', false);

-- Nos posicionamos como el rol de aplicación comprometido (app_web)
SET ROLE app_web;

-- 1. Varios intentos fallidos de inicio de sesión contra fn_autenticar (Fuerza bruta)
SELECT fn_autenticar('carlos.lopez@yahoo.com', '123456');
SELECT fn_autenticar('carlos.lopez@yahoo.com', 'carlos123');
SELECT fn_autenticar('carlos.lopez@yahoo.com', 'admin2026');

-- 2. Inicio de sesión exitoso tras adivinar la credencial
SELECT fn_autenticar('carlos.lopez@yahoo.com', 'CarlosPass99');

-- 3. Lectura masiva de la tabla usuario (Exfiltración de columnas permitidas a app_web)
SELECT id_usuario, nombre, apellido, email, telefono, direccion, rol, fecha_alta, activo
FROM usuario;

-- 4. Intento de escalamiento de privilegios y operación reservada a admin_datos (Punto C.2)
-- Ambos intentos DEBEN FALLAR confirmando que el mínimo privilegio de la Parte A funciona.
DO $$
BEGIN
    -- Intento 4.a: Auto-otorgarse membresía en admin_datos
    EXECUTE 'GRANT admin_datos TO app_web';
EXCEPTION WHEN insufficient_privilege THEN
    RAISE WARNING 'BLOQUEADO (Escalamiento de rol): % (SQLSTATE %)', SQLERRM, SQLSTATE;
END;
$$;

DO $$
BEGIN
    -- Intento 4.b: Ejecutar un borrado reservado a admin_datos sobre la tabla usuario
    EXECUTE 'DELETE FROM usuario WHERE rol = ''admin''';
EXCEPTION WHEN insufficient_privilege THEN
    RAISE WARNING 'BLOQUEADO (Operacion reservada a admin_datos): % (SQLSTATE %)', SQLERRM, SQLSTATE;
END;
$$;

-- Restauramos la sesión al superusuario
RESET ROLE;