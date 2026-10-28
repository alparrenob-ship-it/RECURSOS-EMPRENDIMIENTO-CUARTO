# Aula, semana 8 — etapa 1

## Entregado

- `aula-estudiante.html`: nombre y apellido, curso, paralelo y grupo. Quinto, sexto y séptimo; cuarto no cambia.
- Mi equipo muestra tema, color, integrantes y roles de los equipos originales, sin controles para editarlos.
- Una sola actividad semanal seleccionada explícitamente: ODS vinculados al proyecto. Cuatro ODS distintos, explicaciones, ODS principal y, para séptimo, indicador observable.
- Mi portafolio guarda una única URL de Pages/Keynote compartido por equipo. El repositorio muestra las evidencias semanales sin pedir nuevamente el enlace.
- `aula-docente.html`: actividad por paralelo (borrador/disponible/cerrada), consulta de trabajos y portafolio, rúbrica 4 + 4 + 2, copia del paralelo y acceso a las planificaciones y Equipos originales.
- No se modifican documentos institucionales, sesiones, datos canónicos de equipos ni calificaciones anteriores.

## Límite explícito de esta etapa

No hay servidor ni autenticación institucional. El panel docente existente y el piloto siguen siendo páginas públicas. No son controles de acceso seguros.

Los nuevos datos se guardan solo en localStorage del origen y navegador actual. No se envían al docente desde otros iPad. El piloto marca esta limitación en ambas interfaces. Los nombres se contrastan con la distribución local cuando existe; escribir un nombre no prueba identidad.

Ninguna lista de nombres, nota, enlace compartido ni respuesta se incorpora al repositorio público. Las imágenes y el banco de proyectos ya utilizados son recursos estáticos.

## Persistencia

- `ea-aula-w8-{grado}-{paralelo}-G{grupo}-v1`: un trabajo del equipo para la semana.
- `ea-aula-portafolio-{grado}-{paralelo}-G{grupo}-v1`: enlace permanente, sin semana en la clave.
- `ea-aula-publicacion-{grado}-{paralelo}-w8-v1`: disponibilidad por paralelo.
- `ea-aula-rubrica-w8-{grado}-{paralelo}-G{grupo}-v1`: evaluación semanal separada de las rúbricas de cada sesión.
- sesión del alumno: sessionStorage `ea-aula-estudiante-v1`.
- integrantes: lectura de los registros existentes `emprendimiento-g57-{grado}-{paralelo}-s1`; no se escriben desde el piloto.

## Siguiente etapa: datos centralizados y permisos reales

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
