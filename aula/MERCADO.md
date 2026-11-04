# Investigación de mercado y público objetivo · Séptimo A, B y C

Actividad semana 9, tres diapositivas, una entrega y una evaluación 7+3. Usa siempre el proyecto actual de aula_teams; no reasigna ni completa temas pendientes.

1. Hasta cuatro públicos: imagen JPG optimizada en el navegador y descripción debajo. Los espacios vacíos desaparecen de la presentación.
2. Necesidad por investigar, persona usuaria y comprador (permite explicar «No aplica»).
3. Encuesta, entrevista u observación; cuatro preguntas con tres opciones editables. La entrevista añade seguimiento. La observación pide hechos y una fuente para precios. Las sugerencias se aceptan explícitamente y se adaptan al título/tema actual; no equivalen a resultados de investigación.

El estudiante selecciona un integrante activo antes de aportar. Cada cambio conserva en memoria el integrante seleccionado; un guardado con aportes de varias personas envía lotes separados y mantiene el control de versión. La autoría elegida desde un dispositivo compartido es una declaración de participación, no una nueva autenticación de identidad. La sesión que realiza el registro también queda anotada en la base. Nunca se asignan puntos por contar cambios.

Las contribuciones se guardan en aula_private.market_contributions, sin acceso directo para estudiantes. El snapshot estudiantil no devuelve contribuciones ni evaluaciones. El panel docente las recibe mediante una función que verifica aula_is_teacher. El portafolio abre modo=presentacion: texto e imágenes; imprimir produce tres diapositivas sin selectores de nombre, rúbrica ni etiquetas «Aporte de».

La aplicación de las preguntas se registra como real o ensayo. Cada aplicación conserva una copia de las preguntas/opciones utilizadas, incluso si posteriormente se edita el instrumento. Los participantes se identifican por número de registro, sin pedir nombres. El máximo es 100 aplicaciones por equipo.

Base: aula/sql/008_investigacion_mercado.sql. Publica exclusivamente grado 7, semana 9, A/B/C. Mantiene ODS en semana 8 y reutiliza aula_evaluations con su RPC y reglas de integrantes. Los campos históricos ods_score y reasons_score almacenan respectivamente Público y necesidad /3 e Instrumento /2 solo para esta publicación; teamwork_score /2 y Orden, Organización, Aporte /1 cada uno conservan su significado. No se convierten ni reemplazan evaluaciones de otras semanas.

Validación: SQL ejecutado primero en PGlite con sesiones ficticias: aislamiento por equipo/grado, permisos de estudiante y docente, autoría por campo, conflictos de versión, imágenes y claves válidas, registro de cuatro respuestas en las tres técnicas y una sola evaluación 7+3. Los ensayos locales no usan nombres reales ni escriben en producción.
