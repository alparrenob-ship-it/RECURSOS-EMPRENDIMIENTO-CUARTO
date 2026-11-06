# Cuarto: aula dirigida y portafolio compartido

La docente dirige y edita desde las planificaciones. Los estudiantes consultan su propio equipo y calificación. Las escrituras se autorizan en el servidor mediante aula_is_teacher, nunca mediante un parámetro de URL.

Cada semana desde la 9 mantiene dos accesos: Sesión 1 (comprender) y Sesión 2 (Actividad propuesta). El acceso Portafolio se encuentra en la sección general de cuarto. Su organización es paralelo A/B/C → grupo con color → ficha editable → Mi portafolio.

cuarto-panel.html?docente=1 abre el área docente. cuarto-panel.html abre la consulta estudiantil; el mismo curso se ofrece en aula-estudiante.html. La identidad estudiantil usa la sesión anónima existente y la inscripción al equipo. No admite editar desde cuarto ni mediante endpoints antiguos.

Las fuentes de proyectos son las asignaciones del Banco de Proyectos V2. Las migraciones 018 y 019 crean los equipos y sus textos/ODS iniciales. No incluyen nombres de estudiantes. La primera apertura docente recupera los integrantes locales solo cuando el equipo compartido está vacío. El botón Sincronizar integrantes permite actualizarlos. Las respuestas locales anteriores se recuperan sin reemplazar respuestas compartidas ya guardadas.

La presentación inicia con portada editable, ODS, problema, solución y público objetivo. Las respuestas guardadas de semana 9 se muestran en diapositivas de resultados. La actividad sigue cinco turnos, con integrante seleccionado por tarjeta. La rúbrica permanece en la actividad: actividad 4 + equipo 2, y orden 1 + organización 1 + aporte 2 individual. Las notas no pasan automáticamente al registro institucional. La consulta estudiantil solo recibe su propia evaluación individual.

El documento compartido usa versión optimista; una sesión no puede sobrescribir sin aviso cambios de otra. Las imágenes se preparan en el navegador antes de guardar. El modo de presentación conserva proporción 16:9 y ofrece alternativa para Safari.

Pruebas: node aula/tests/fourth-cloud-ui.cjs; node aula/tests/market-v2.cjs; node semana9/tests/cuarto.cjs. La prueba SQL transaccional verificó escritura docente, consulta estudiantil, aislamiento de notas individuales, conflicto de versión y bloqueo de escritura antigua; no dejó personas ni calificaciones ficticias guardadas.
