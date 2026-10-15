\# Diseño Técnico de Permisos y Seguridad (Food Store)



\## 1. Arquitectura de Herencia (RBAC)

Se separa estrictamente la asignación de privilegios (roles de grupo `NOLOGIN`) de la autenticación de conexiones (roles `LOGIN`):

\* `app\_web (LOGIN)` -> hereda `rol\_app\_lectura`, `rol\_app\_escritura`.

\* `admin\_datos (LOGIN)` -> hereda `rol\_app\_lectura`, `rol\_app\_escritura`, `rol\_reportes` + permisos sobre datos maestros.

\* `soporte\_operador (LOGIN)` -> hereda `rol\_soporte`.



\## 2. Protección a Nivel de Columna (Tabla `usuario`)

Para evitar la exposición del atributo sensible `password\_hash`, se revoca el `SELECT` general sobre la tabla `usuario` y se otorga permiso explícito por columna:

\* `rol\_app\_lectura`: `SELECT (id\_usuario, nombre, apellido, email, telefono, direccion, rol, fecha\_alta, activo) ON usuario`.

\* `rol\_soporte`: `SELECT (id\_usuario, nombre, apellido, email, telefono, rol, activo) ON usuario`.

\* `rol\_auditor\_interno`: `SELECT (id\_usuario, email, rol, fecha\_alta, activo) ON usuario`.



\## 3. Encapsulamiento mediante Funciones `SECURITY DEFINER`

\* `fn\_autenticar`: Ejecutable por `rol\_app\_escritura` (`app\_web`). Valida credenciales internamente sin que el rol lector tenga permiso sobre `password\_hash`.

\* `fn\_resetear\_password`: Ejecutable únicamente por `rol\_soporte` y `admin\_datos`.



\## 4. Políticas por Defecto (`ALTER DEFAULT PRIVILEGES`)

Se configura `ALTER DEFAULT PRIVILEGES IN SCHEMA public` para que toda tabla futura creada en el esquema otorgue automáticamente `SELECT` a `rol\_app\_lectura` y `rol\_reportes`, manteniendo la política sin intervención manual ni sobreasignación.

