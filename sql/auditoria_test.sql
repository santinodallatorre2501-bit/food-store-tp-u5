-- =================================================================
-- PARTE B: ACTIVACIÓN Y PRUEBA DE LA AUDITORÍA (FOOD STORE)
-- =================================================================

-- 1. Activación de parámetros de auditoría (Punto B.1)
-- Nota: Si se ejecutan de a una línea fuera de transacción se puede usar:
-- ALTER SYSTEM SET log_connections = 'on';
-- ALTER SYSTEM SET log_disconnections = 'on';
-- ALTER SYSTEM SET log_statement = 'all';
-- SELECT pg_reload_conf();

-- Aplicamos la configuración activa en el motor compatible con ejecución en bloque (F5):
SELECT set_config('log_statement', 'all', false);

-- Verificamos cómo quedaron los parámetros en el servidor
SELECT name AS parametro, setting AS valor_activo
FROM pg_settings
WHERE name IN ('log_connections', 'log_disconnections', 'log_statement', 'log_line_prefix');

-- =================================================================
-- 2. Secuencia breve de operaciones de prueba (Punto B.2)
-- =================================================================

-- 2.a Lectura (SELECT sobre catálogo)
SELECT id_producto, nombre, precio_lista, stock 
FROM producto 
ORDER BY id_producto 
LIMIT 5;

-- 2.b Inserción (INSERT de un producto de prueba)
INSERT INTO producto (nombre, precio_lista, stock, id_categoria)
VALUES ('Aceite de Oliva Extra Virgen 500ml', 8500.00, 40, (SELECT MIN(id_categoria) FROM categoria));

-- 2.c Actualización (UPDATE de stock y precio sobre el producto insertado)
UPDATE producto
SET stock = 38, precio_lista = 8900.00
WHERE nombre = 'Aceite de Oliva Extra Virgen 500ml';

-- 2.d Intento de inicio de sesión fallido (contra fn_autenticar)
SELECT fn_autenticar('juan.perez@gmail.com', 'ClaveIncorrecta999');