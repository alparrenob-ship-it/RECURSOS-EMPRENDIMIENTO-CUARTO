# Aula, semana 8 — acceso docente conectado

## Entregado

- `aula-estudiante.html`: nombre y apellido, curso, paralelo y grupo. Quinto, sexto y séptimo; cuarto no cambia.
- Mi equipo muestra tema, color, integrantes y roles de los equipos originales, sin controles para editarlos.
- Una sola actividad semanal seleccionada explícitamente: ODS vinculados al proyecto. Cuatro ODS distintos, explicaciones, ODS principal y, para séptimo, indicador observable.
- Mi portafolio guarda una única URL de Pages/Keynote compartido por equipo. El repositorio muestra las evidencias semanales sin pedir nuevamente el enlace.
- `aula-docente.html`: actividad por paralelo (borrador/disponible/cerrada), consulta de trabajos y portafolio, rúbrica 4 + 4 + 2, copia del paralelo y acceso a las planificaciones y Equipos originales.
- No se modifican documentos institucionales, sesiones, datos canónicos de equipos ni calificaciones anteriores.

## Estado actual

El panel docente verifica la sesión mediante Supabase Auth, consulta `aula_is_teacher` en el servidor y solo después muestra los datos. El correo de la lista privada debe estar confirmado. La página de inicio ofrece dos accesos y revela las planificaciones al docente autorizado. Los archivos estáticos de las planificaciones no son documentos privados; los nombres, enlaces y calificaciones de la base de datos sí se protegen mediante RLS.

El panel docente lee y guarda equipos, integrantes, publicaciones, respuestas, portafolios y rúbricas desde las tablas de Supabase. Primero incorpora los proyectos conocidos del banco, sin nombres de alumnos. La docente puede importar explícitamente los equipos guardados en su navegador o registrar integrantes desde cada equipo. Retirar un integrante lo desactiva, sin borrar sus evaluaciones.

El acceso estudiantil continúa en piloto local, pendiente del paso 2: sesiones de alumnos validadas por docente y políticas de lectura/escritura por equipo. Los estudiantes todavía no envían entregas en línea. No habilitar acceso anónimo general a las tablas.

No se borran los registros anteriores del navegador ni se incorporan datos escolares al repositorio público. La clave publishable es pública; las claves secret/service_role nunca se utilizan en el navegador.

El cierre de sesión borra la caché docente y cierra esa sesión de Supabase; conserva las listas y actividades locales anteriores. Un fallo de red nunca se anuncia como guardado en línea ni se sustituye silenciosamente por almacenamiento local.

Las notas grupales e individuales se guardan mediante solicitudes separadas. Si falla el aporte individual después del guardado grupal, la interfaz informa el guardado parcial y requiere revisar y volver a guardar; aún no se usa una transacción RPC para toda la evaluación.

## Persistencia

- `ea-aula-w8-{grado}-{paralelo}-G{grupo}-v1`: un trabajo del equipo para la semana.
- `ea-aula-portafolio-{grado}-{paralelo}-G{grupo}-v1`: enlace permanente, sin semana en la clave.
- `ea-aula-publicacion-{grado}-{paralelo}-w8-v1`: disponibilidad por paralelo.
- `ea-aula-rubrica-w8-{grado}-{paralelo}-G{grupo}-v1`: evaluación semanal separada de las rúbricas de cada sesión.
- sesión del alumno: sessionStorage `ea-aula-estudiante-v1`.
- integrantes: lectura de los registros existentes `emprendimiento-g57-{grado}-{paralelo}-s1`; no se escriben desde el piloto.

## Siguiente etapa: permisos y envío de estudiantes

Se necesita un servicio de autenticación y base de datos, y confirmar el correo institucional de la docente. Supabase es una opción: acceso por enlace de correo y PostgreSQL con políticas de seguridad por fila.

Antes de usarlo con alumnos de forma compartida:

1. Autorizar explícitamente el servicio/proyecto de datos y el correo docente. No añadir claves privadas al sitio.
2. Registrar docente verificado, cursos/paralelos, equipos, integrantes y roles. La asignación la escribe exclusivamente la docente, mediante comprobación en servidor.
3. Resolver acceso simple de alumnos mediante sesión validada contra el equipo y, si se acuerda, código del aula. El nombre por sí solo no es una contraseña.
4. Publicaciones: una actividad por semana y paralelo, elegida por la docente. Nada se publica automáticamente desde todas las sesiones.
5. Estudiantes solo leen su equipo y publicaciones permitidas; escriben evidencias y portafolio de su equipo. No pueden cambiar equipos, publicaciones ni calificaciones por API.
6. Rúbricas y notas: lectura/escritura docente. Mostrar al alumno solo lo que la docente decida publicar.
7. Migrar los registros locales privados mediante una sesión docente; comprobar dispositivo diferente, cierre de actividad, intentos de acceso de otro equipo y recuperación de datos.

Referencias oficiales:
- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/guides/database/postgres/row-level-security


## Paso 2: estudiantes en línea
Ejecutar `sql/002_acceso_estudiantil.sql` después de 001 y activar Allow anonymous sign-ins en Supabase Auth. `aula-paso2.html` permite copiar el script. La página estudiantil usa una sesión anónima con clave de almacenamiento separada de la docente y RPC limitadas a su equipo. No hay políticas de lectura pública de tablas. El ingreso exige nombre y apellido, curso, paralelo y grupo; normaliza tildes, espacios y mayúsculas y acepta el orden inverso de nombres guardados. Nombres ausentes o ambiguos se rechazan. El rechazo aparece en rojo.

El ingreso comprueba pertenencia al padrón, no identidad personal: conocer los datos de otro estudiante permitiría intentar suplantarlo. No se usan nombres como contraseñas secretas. Una baja en aula_members.active revoca el acceso en cada consulta/guardado. Los trabajos se guardan por equipo; la última edición guardada sustituye la anterior. Los registros antiguos del navegador no se importan automáticamente.

Hasta ejecutar 002 y activar las sesiones anónimas, la nueva página rechaza el acceso con un mensaje de configuración pendiente. Para probar basta un paralelo importado, por ejemplo Quinto A; no es necesario esperar a todos. Publicaciones en borrador quedan ocultas.
