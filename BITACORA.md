\# Bitácora de Uso de IA - TP Unidad 5 (Food Store)



| Etapa / Parte | Prompt enviado a la IA (OpenCode) | Respuesta relevante recibida (Resumen) | Validación o corrección humana aplicada |

| :--- | :--- | :--- | :--- |

| \*\*Paso Previo (Reconstrucción)\*\* | \*"Generá el script SQL para PostgreSQL que reconstruya la tabla `usuario` de Food Store con datos de prueba y las funciones `fn\_autenticar` y `fn\_resetear\_password` vistas en las Clases 1 y 2."\* | Entregó el DDL de `usuario`, un lote de 10 registros con distintos roles/fechas de alta y las funciones PL/pgSQL con `SECURITY DEFINER`. | \*\*Validado y ajustado:\*\* Se verificó que las funciones usen `md5()` nativo y `SECURITY DEFINER` para que los roles operativos puedan autenticar o resetear claves sin tener permiso `SELECT` o `UPDATE` directo sobre la columna `password\_hash`. |

| \*\*Parte A (Auditoría de `roles.sql`)\*\* | \*"Auditá nuestro archivo `sql/roles.sql` para Food Store y proponé mejoras o correcciones para la gestión de permisos de los roles."\* | Propuso simplificar el script usando `GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin\_datos, rol\_app\_escritura;` y dar `SELECT` completo sobre `usuario` a `rol\_soporte`. | \*\*Rechazado y corregido:\*\* Se descartó el `GRANT ALL` porque viola el principio de mínimo privilegio (otorgaría `DELETE`, `TRUNCATE` y `REFERENCES` a `rol\_app\_escritura`, permitiendo borrar pedidos). También se rechazó dar `SELECT \* ON usuario` a `rol\_soporte` para no exponer `password\_hash`, manteniendo el `GRANT SELECT` a nivel de columnas específicas. |

| **Parte B (Configuración de Auditoría)** | *"Generá los comandos para activar la auditoría en PostgreSQL (`log_connections`, `log_disconnections`, `log_statement`) y un script de prueba con lectura, inserción, actualización y login fallido."* | Sugirió configurar `log_statement = 'mod'` en `postgresql.conf` y propuso ejecutar las pruebas sin modificar `log_line_prefix`. | **Corregido y ampliado:** Se cambió `log_statement` a `'all'` durante la prueba porque con `'mod'` no quedaban registrados el `SELECT` de lectura ni la invocación a `SELECT fn_autenticar(...)` requeridos en el punto B.2. Además, se configuró `log_line_prefix` con `%m [%p] %q%u@%d/%a (%h)` para capturar quién, cuándo y desde dónde. |