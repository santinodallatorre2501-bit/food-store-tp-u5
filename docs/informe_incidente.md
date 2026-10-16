\# Informe de Laboratorio: Simulacro de Incidente de Acceso Indebido (Parte C)



\## 1. Verificación del Bloqueo de Escalamiento (Punto C.2)

Al ejecutar `sql/simulacro\_incidente.sql` bajo el rol `app\_web`, los dos intentos de escalamiento de privilegios \*\*fallaron efectivamente\*\*:

1\. `GRANT admin\_datos TO app\_web;` fue rechazado con `ERROR: permission denied to grant role "admin\_datos" (SQLSTATE 42501)`.

2\. `DELETE FROM usuario WHERE rol = 'admin';` fue rechazado con `ERROR: permission denied for table usuario (SQLSTATE 42501)`.



\*\*Conclusión de verificación:\*\* El esquema de permisos diseñado en la Parte A es sólido; `app\_web` no posee el atributo `CREATEROLE` ni `ADMIN OPTION` sobre `admin\_datos`, ni privilegios de borrado sobre `usuario`, conteniendo el daño potencial del incidente.



\---



\## 2. Reconstrucción generada por la IA a partir del Log Anonimizado (Punto C.4)

Se entregó únicamente el contenido de `docs/log\_simulacro\_anonimizado.txt` a OpenCode sin contexto adicional. A continuación se transcribe la respuesta completa recibida:



> \*\*Respuesta de OpenCode (IA):\*\*

> "A partir del análisis del log provisto, se reconstruye el siguiente incidente ocurrido el 16/10/2026 entre las 01:15:02 y las 01:15:15 desde la IP `10.0.0.55`:

> 1. \*\*Acceso inicial mediante SQL Injection:\*\* Un atacante externo vulneró el endpoint web de login inyectando llamadas directas a `fn\_autenticar` desde el cliente `pgAdmin 4`.

> 2. \*\*Ataque de fuerza bruta:\*\* Se observan 3 intentos fallidos consecutivos contra la cuenta `usr\_003@anon.foodstore.local` en menos de 2 segundos, seguidos de un cuarto intento exitoso a las 01:15:05.512.

> 3. \*\*Exfiltración total de credenciales:\*\* A las 01:15:08, el atacante ejecutó un `SELECT` masivo sobre la tabla `usuario`, logrando robar la totalidad de la base de usuarios incluyendo sus hashes de contraseñas (`password\_hash`).

> 4. \*\*Intento fallido de escalamiento y sabotaje:\*\* A las 01:15:11 intentó asignarse el rol `admin\_datos` y a las 01:15:12 intentó eliminar a los usuarios con rol `'admin'`, siendo bloqueado en ambos casos por falta de permisos (`permission denied`).

> 

> \*\*Hipótesis de contención sugerida por la IA:\*\*

> Ejecutar inmediatamente `DROP ROLE app\_web;`, bloquear la IP `10.0.0.55` en el firewall perimetral y obligar al cambio de contraseña de todos los usuarios del sistema debido al robo de `password\_hash`."



\---



\## 3. Lectura Crítica y Contraste contra lo Realmente Ejecutado (Punto C.5)

Al contrastar la reconstrucción de la IA contra el script real ejecutado por el equipo (`sql/simulacro\_incidente.sql`), se identifican aciertos pero también \*\*alucinaciones y afirmaciones sin sustento en la evidencia\*\*:



\* \*\*Qué acertó la IA:\*\*

&#x20; \* Identificó correctamente la línea de tiempo (12.8 segundos), el PID del proceso (`18412`), el rol de base de datos utilizado (`app\_web`) y el origen (`10.0.0.55`).

&#x20; \* Detectó con exactitud la secuencia de 3 intentos fallidos seguidos de 1 login exitoso sobre `fn\_autenticar`, el `SELECT` posterior sobre `usuario`, y que los dos intentos de escalamiento (`GRANT` y `DELETE`) fueron rechazados por el motor.

\* \*\*Qué omitió la IA:\*\*

&#x20; \* No advirtió la anomalía crítica de contexto de aplicación: el rol de servicio `app\_web` se estaba conectando desde una herramienta interactiva de administración (`application\_name="pgAdmin 4"`) en lugar del pool de conexiones del backend web, lo cual indica robo de credenciales de la cuenta de servicio `app\_web` y no un simple abuso desde el formulario web.

\* \*\*Afirmaciones falsas o no sustentadas por el log (Errores de la IA):\*\*

&#x20; 1. \*\*Inventó la causa raíz (SQL Injection):\*\* El log solo muestra sentencias ejecutadas en una sesión autenticada como `app\_web`; no existe ninguna evidencia en el log de PostgreSQL que sustente una inyección SQL (no hay comillas rotas, `UNION SELECT` ni errores de sintaxis).

&#x20; 2. \*\*Afirmó falsamente el robo de `password\_hash`:\*\* La IA aseguró que se robaron los hashes de contraseñas en el `SELECT` masivo, cuando el comando literal registrado en el log a las `01:15:08.220` lista explícitamente las columnas (`id\_usuario, nombre, apellido, email, telefono, direccion, rol, fecha\_alta, activo`) \*\*sin incluir `password\_hash`\*\* (columna a la cual `app\_web` ni siquiera tiene permiso de lectura según el diseño de la Parte A).

&#x20; 3. \*\*Medida de contención destructiva:\*\* Propuso `DROP ROLE app\_web;`, lo cual no solo fallaría en PostgreSQL por tener dependencias de permisos, sino que dejaría fuera de servicio toda la tienda en producción.



\---



\## 4. Decisión Final de Contención del Equipo (Punto C.6)

Descartando las suposiciones sin evidencia de la IA y basándonos estrictamente en los hechos comprobados en el log y en nuestra arquitectura de permisos, el equipo define el siguiente plan de contención:



1\. \*\*Rotación inmediata de la credencial del rol `app\_web` y restricción en `pg\_hba.conf`:\*\* Como la evidencia muestra una conexión directa con `app\_web` desde `pgAdmin 4` (`10.0.0.55`), se cambia la contraseña del rol (`ALTER ROLE app\_web WITH PASSWORD ...`), se cierran sus sesiones activas (`pg\_terminate\_backend`) y se restringe en `pg\_hba.conf` para que `app\_web` solo pueda conectarse desde la IP exacta del servidor backend de la aplicación.

2\. \*\*Bloqueo preventivo y reseteo de clave únicamente del usuario afectado (`carlos.lopez@yahoo.com`):\*\* A diferencia de lo sugerido por la IA, \*\*no se fuerza el reseteo masivo de contraseñas de toda la base\*\* porque `password\_hash` nunca fue expuesto. Solo se fuerza el reseteo de la cuenta vulnerada por fuerza bruta (`fn\_resetear\_password`) y se implementa \*rate-limiting\* / bloqueo por intentos fallidos en la aplicación.

3\. \*\*Notificación por exposición de datos personales (PII):\*\* Dado que el `SELECT` masivo sí leyó nombres, emails, teléfonos y direcciones de la tabla `usuario`, se registra el incidente de acceso a datos personales sin caída del servicio.



\*Esta decisión de contención es tomada íntegramente por el equipo a partir de la evidencia técnica verificada, evitando ejecutar automáticamente acciones destructivas sugeridas por el asistente de IA.\*

