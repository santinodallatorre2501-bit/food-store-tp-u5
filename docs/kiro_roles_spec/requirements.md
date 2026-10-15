\# Especificación de Requerimientos: Esquema de Roles y Mínimo Privilegio (Food Store)



\## Objetivo

Definir el modelo de identidades y control de acceso basado en roles (RBAC) para la base de datos de Food Store bajo el principio de mínimo privilegio.



\## Requerimientos de Roles de Grupo (NOLOGIN)

1\. \*\*rol\_app\_lectura:\*\* Habilita exclusivamente la lectura (`SELECT`) sobre el catálogo, pedidos y columnas públicas de `usuario` (excluyendo `password\_hash`), porque la capa de presentación necesita mostrar datos sin exponer hashes de credenciales ni modificar registros.

2\. \*\*rol\_app\_escritura:\*\* Habilita la inserción y actualización operativa (`INSERT`, `UPDATE`) sobre `cliente`, `pedido` y `detalle\_pedido`, además de la ejecución de `fn\_autenticar`, porque el flujo transaccional de compras requiere registrar operaciones sin tener permiso de borrado físico (`DELETE`) ni acceso directo a credenciales.

3\. \*\*rol\_soporte:\*\* Habilita la consulta de pedidos/clientes, la vista parcial de `usuario` (sin `password\_hash`) y la ejecución de `fn\_resetear\_password`, porque el área de atención al cliente necesita asistir usuarios y blanquear claves sin poder leer hashes ni alterar ventas.

4\. \*\*rol\_reportes:\*\* Habilita únicamente la lectura (`SELECT`) sobre tablas de ventas (`pedido`, `detalle\_pedido`, `categoria`, `producto` y `reporte\_diario\_categoria`), porque el área de analítica requiere calcular métricas comerciales sin acceder a datos personales de `usuario`.

5\. \*\*rol\_auditor\_interno (Rol adicional del equipo):\*\* Habilita la lectura acotada sobre metadatos de cuentas en `usuario` (`id\_usuario`, `email`, `rol`, `fecha\_alta`, `activo`) y `reporte\_diario\_categoria`, porque el control interno requiere verificar altas y cierres diarios sin acceder a teléfonos, direcciones ni contraseñas.



\## Requerimientos de Roles de Login (LOGIN)

1\. \*\*app\_web:\*\* Cuenta de servicio para el backend de la tienda que hereda `rol\_app\_lectura` y `rol\_app\_escritura`, porque el sistema web necesita operar el ciclo comercial completo sin poseer privilegios administrativos ni de estructura (DDL).

2\. \*\*admin\_datos:\*\* Cuenta para la administración de datos que hereda lectura, escritura y reportes junto con permisos de mantenimiento sobre las tablas del negocio, porque requiere gestionar el catálogo y los datos maestros sin usar el superusuario `postgres`.

3\. \*\*soporte\_operador (Rol de login adicional del equipo):\*\* Cuenta nominada para operadores de mesa de ayuda que hereda únicamente `rol\_soporte`, porque permite aislar y auditar el accionar de soporte técnico frente a incidentes.

