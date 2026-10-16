\# Informe de Configuración y Análisis de Auditoría (Food Store)



\## 0. Anexo Parte A.3: Salida de Verificación de Permisos

Se adjunta el resultado de verificar los roles con `\\du` y la consulta sobre `information\_schema.role\_table\_grants` tras ejecutar `sql/roles.sql`:



\### Salida equivalente a `\\du` (Roles y Membresías)

| rol | puede\_loguear | hereda\_de |

| :--- | :--- | :--- |

| `rol\_app\_escritura` | `false` | `{}` |

| `rol\_app\_lectura` | `false` | `{}` |

| `rol\_auditor\_interno` | `false` | `{}` |

| `rol\_reportes` | `false` | `{}` |

| `rol\_soporte` | `false` | `{}` |

| `admin\_datos` | `true` | `{rol\_app\_lectura,rol\_app\_escritura,rol\_reportes}` |

| `app\_web` | `true` | `{rol\_app\_lectura,rol\_app\_escritura}` |

| `soporte\_operador` | `true` | `{rol\_soporte}` |



\### Salida de `information\_schema.role\_table\_grants`

| rol | tabla | privilegios |

| :--- | :--- | :--- |

| `admin\_datos` | `categoria` | `DELETE, INSERT, UPDATE` |

| `admin\_datos` | `producto` | `DELETE, INSERT, UPDATE` |

| `admin\_datos` | `usuario` | `DELETE, INSERT, UPDATE` |

| `rol\_app\_escritura` | `cliente` | `INSERT, UPDATE` |

| `rol\_app\_escritura` | `detalle\_pedido` | `INSERT, UPDATE` |

| `rol\_app\_escritura` | `pedido` | `INSERT, UPDATE` |

| `rol\_app\_lectura` | `categoria` | `SELECT` |

| `rol\_app\_lectura` | `cliente` | `SELECT` |

| `rol\_app\_lectura` | `detalle\_pedido` | `SELECT` |

| `rol\_app\_lectura` | `pedido` | `SELECT` |

| `rol\_app\_lectura` | `producto` | `SELECT` |

| `rol\_app\_lectura` | `usuario` | `SELECT` \*(acotado a columnas sin `password\_hash`)\* |

| `rol\_auditor\_interno` | `reporte\_diario\_categoria` | `SELECT` |

| `rol\_auditor\_interno` | `usuario` | `SELECT` \*(acotado a metadatos)\* |

| `rol\_reportes` | `categoria` | `SELECT` |

| `rol\_reportes` | `detalle\_pedido` | `SELECT` |

| `rol\_reportes` | `pedido` | `SELECT` |

| `rol\_reportes` | `producto` | `SELECT` |

| `rol\_reportes` | `reporte\_diario\_categoria` | `SELECT` |

| `rol\_soporte` | `cliente` | `SELECT` |

| `rol\_soporte` | `detalle\_pedido` | `SELECT` |

| `rol\_soporte` | `pedido` | `SELECT` |

| `rol\_soporte` | `usuario` | `SELECT` \*(acotado a columnas de atención)\* |



\---



\## 1. Parámetros de Auditoría Modificados (Punto B.1)

Mediante `ALTER SYSTEM` y recarga con `pg\_reload\_conf()`, se configuraron los siguientes parámetros en el motor PostgreSQL 16:



| Parámetro | Valor Configurado | Propósito en la Auditoría |

| :--- | :--- | :--- |

| `log\_connections` | `on` | Registra cada intento de conexión al servidor y su autorización exitosa o fallida. |

| `log\_disconnections` | `on` | Registra el cierre de sesión junto con la duración total de la conexión. |

| `log\_statement` | `all` \*(supera el mínimo `mod`)\* | Registra tanto las operaciones de modificación (`INSERT`, `UPDATE`, `DELETE`, `DDL`) como las consultas de lectura (`SELECT`) e invocaciones a funciones para poder trazabilizar la secuencia completa de prueba. |

| `log\_line\_prefix` | `'%m \[%p] %q%u@%d/%a (%h) '` | Añade contexto de rendición de cuentas en cada línea: marca temporal con milisegundos (`%m`), PID del proceso (`%p`), usuario (`%u`), base de datos (`%d`), aplicación (`%a`) e IP de origen (`%h`). |



\---



\## 2. Análisis del Fragmento de Log Capturado (Punto B.3)



\### Información útil para auditoría (Rendición de cuentas)

Sobre el archivo `docs/log\_auditoria\_prueba.txt`, el prefijo configurado y las directivas activas permiten responder las cuatro preguntas forenses básicas:

\* \*\*Quién (`%u`):\*\* Se identifica el rol de base de datos que ejecutó cada acción (`app\_web`, `postgres`, y el intento fallido sobre `admin\_datos`), además del correo evaluado en el `WARNING` de `fn\_autenticar` (`juan.perez@gmail.com`).

\* \*\*Qué (`LOG: statement` / `WARNING` / `FATAL`):\*\* Queda registrada la sentencia SQL literal ejecutada (el `SELECT` de productos, el `INSERT` del aceite de oliva, el `UPDATE` de stock/precio y el llamado a `fn\_autenticar`), así como el rechazo de autenticación por contraseña inválida.

\* \*\*Cuándo (`%m`):\*\* Cada evento posee fecha, hora exacta con precisión de milisegundos y zona horaria (`2026-10-15 19:50:14.302 -03`), más el tiempo total de sesión al desconectar (`session time: 0:00:13.308`).

\* \*\*Desde dónde (`%h` y `%a`):\*\* Se identifica la dirección IP de origen (`127.0.0.1`), el puerto efímero (`port=54322`) y la aplicación cliente utilizada (`pgAdmin 4` o `psql`).



\### Limitaciones del mecanismo nativo frente a `pgaudit`

Si se requiriera mayor granularidad, el log nativo con `log\_statement` deja fuera de alcance aspectos críticos que sí resuelve la extensión \*\*`pgaudit`\*\*:

1\. \*\*Detalle fila por fila y valores previos/nuevos:\*\* El log nativo solo muestra el texto del comando `UPDATE` o `SELECT`, pero no indica cuántas ni cuáles filas exactas fueron afectadas o leídas, ni cuál era el valor anterior antes del cambio.

2\. \*\*Auditoría selectiva por objeto o rol (Object Audit Logging):\*\* `log\_statement` es global y genera mucho ruido; `pgaudit` permite auditar exclusivamente cuando se toca una tabla sensible específica (como `usuario`) sin llenar el disco con lecturas de catálogo.

3\. \*\*Consultas dinámicas dentro de funciones PL/pgSQL:\*\* El log nativo muestra la llamada externa `SELECT fn\_autenticar(...)`, mientras que `pgaudit` permite desglosar las sentencias internas ejecutadas dentro del cuerpo de la función `SECURITY DEFINER`.



\---



\## 3. El Archivo de Log como Activo Sensible (Punto B.4)

El archivo de log es, en sí mismo, un \*\*activo altamente sensible\*\* porque almacena en texto plano consultas SQL que pueden contener datos personales (emails, nombres, direcciones) e incluso credenciales o parámetros enviados a funciones como `fn\_autenticar('juan.perez@gmail.com', 'ClaveIncorrecta999')`. 



Por este motivo, \*\*solo el administrador del motor (DBA) y el equipo de Seguridad/Auditoría\*\* deberían poder leerlo, nunca los roles de aplicación (`app\_web`) ni usuarios de soporte. A nivel de sistema operativo, los archivos dentro del directorio de logs deben pertenecer exclusivamente al usuario de servicio `postgres` con permisos restrictivos (`0600` o `0640`), y a nivel del motor el rol predefinido `pg\_read\_server\_files` debe estar estrictamente revocado para cualquier cuenta que no sea de administración de seguridad.

