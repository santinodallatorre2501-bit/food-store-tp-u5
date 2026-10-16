# Verificación de Equivalencia Analítica y Protección de Datos (Parte D)

## 1. Especificación de las Consultas de Agregación (Punto D.2)
Se solicitó a OpenCode una consulta de agregación sobre usuario_anon que calcule la cantidad total de usuarios y la cantidad de usuarios activos agrupados por mes de alta (YYYY-MM) y por rol, y su consulta homóloga sobre la tabla real usuario.

### Consulta 1: Sobre tabla anonimizada (usuario_anon)
SELECT 
    TO_CHAR(DATE_TRUNC('month', fecha_alta), 'YYYY-MM') AS mes_alta,
    rol,
    COUNT(*) AS total_usuarios,
    SUM(CASE WHEN activo THEN 1 ELSE 0 END) AS usuarios_activos
FROM usuario_anon
GROUP BY DATE_TRUNC('month', fecha_alta), rol
ORDER BY mes_alta, rol;

### Consulta 2: Sobre tabla real (usuario)
SELECT 
    TO_CHAR(DATE_TRUNC('month', fecha_alta), 'YYYY-MM') AS mes_alta,
    rol,
    COUNT(*) AS total_usuarios,
    SUM(CASE WHEN activo THEN 1 ELSE 0 END) AS usuarios_activos
FROM usuario
GROUP BY DATE_TRUNC('month', fecha_alta), rol
ORDER BY mes_alta, rol;

## 2. Comparación de Resultados Agregados Lado a Lado (Punto D.3)
Al ejecutar ambas sentencias sobre la base de datos de Food Store (tp3), se obtiene exactamente el mismo conjunto de resultados, demostrando que la anonimización determinista protege la identidad individual sin distorsionar el comportamiento estadístico del negocio:

| Resultado sobre usuario_anon (mes_alta - rol - total - activos) | Resultado sobre usuario real (mes_alta - rol - total - activos) | Coincide |
| :--- | :--- | :---: |
| 2026-01 - cliente - 2 - 2 | 2026-01 - cliente - 2 - 2 | Sí (100%) |
| 2026-02 - cliente - 1 - 1 | 2026-02 - cliente - 1 - 1 | Sí (100%) |
| 2026-02 - soporte - 1 - 1 | 2026-02 - soporte - 1 - 1 | Sí (100%) |
| 2026-02 - vendedor - 1 - 1 | 2026-02 - vendedor - 1 - 1 | Sí (100%) |
| 2026-03 - admin - 1 - 1 | 2026-03 - admin - 1 - 1 | Sí (100%) |
| 2026-03 - cliente - 1 - 1 | 2026-03 - cliente - 1 - 1 | Sí (100%) |
| 2026-03 - vendedor - 1 - 1 | 2026-03 - vendedor - 1 - 1 | Sí (100%) |
| 2026-04 - cliente - 2 - 1 | 2026-04 - cliente - 2 - 1 | Sí (100%) |

## 3. Frontera de Protección de Datos frente a Asistentes de IA (Punto D.4)
Jamás deben enviarse hacia un asistente de IA externo sin previa anonimización los datos personales identificables (PII) almacenados en usuario y cliente (nombres y apellidos reales, direcciones de correo electrónico, números de teléfono y domicilios físicos de entrega), así como tampoco los secretos de autenticación y seguridad (password_hash, contraseñas en texto plano capturadas en invocaciones a fn_autenticar dentro de archivos de log, ni direcciones IP reales o credenciales de conexión de los roles de base de datos). Exponer estos atributos en un prompt o fragmento de log crudo vulnera la privacidad de las personas y compromete la seguridad operativa de Food Store fuera del perímetro controlado de la organización.