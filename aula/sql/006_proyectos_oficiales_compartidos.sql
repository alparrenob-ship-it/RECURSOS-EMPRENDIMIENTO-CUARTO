-- PASO 6 · Proyectos oficiales asignados y edición compartida.
-- Fuente: Banco de Proyectos V2. Séptimo C queda pendiente por indicación docente.
-- No se editan listas, roles, actividades ni calificaciones.
-- Cada proyecto se carga una sola vez. Repetir el script conserva cambios posteriores.
BEGIN;
CREATE TABLE IF NOT EXISTS aula_private.project_source_imports (
 team_id uuid NOT NULL REFERENCES public.aula_teams(id),
 source_version text NOT NULL,
 source_option text NOT NULL,
 source_row integer NOT NULL,
 previous_title text NOT NULL,
 previous_problem text NOT NULL,
 previous_solution text NOT NULL,
 loaded_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(team_id,source_version)
);
ALTER TABLE aula_private.project_source_imports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE aula_private.project_source_imports FROM PUBLIC,anon,authenticated;

-- 5.º EGB: 12 proyectos asignados, separados por paralelo y grupo.
WITH source(grade,parallel,group_number,option_id,source_row,title,problem,solution) AS (VALUES
(5,'A',1,'49',150,'Agenda Smart: agenda física personalizada conectada por QR a un planificador digital semanal.','Los estudiantes necesitan organizar tareas y compromisos de la semana en un lugar fácil de consultar. Una agenda física, por sí sola, puede quedar desconectada del plan digital que utilizan para actualizar sus pendientes. Esto puede dificultar encontrar la información vigente y seguir lo que deben realizar cada día.

El equipo investigará cómo planifican sus tareas los estudiantes y qué información necesitan ver primero. El reto es conectar ambos soportes para facilitar la planificación, sin duplicar registros innecesarios.','Diseñar una agenda física personalizada que incorpore un código QR hacia un planificador semanal digital. La agenda permitirá identificar a su usuario y el QR abrirá la plantilla correspondiente; allí se organizarán las tareas por día y se distinguirán los pendientes de los terminados.

La primera versión incluirá un modelo de agenda, el QR funcional y una plantilla digital comprensible en el iPad. Durante la prueba, un estudiante escaneará el código, localizará su semana y registrará una tarea. El equipo observará si puede hacerlo con claridad y registrará las tareas planificadas para decidir qué mejorar del diseño y del acceso.'),
(5,'A',2,'50',151,'Circular Shop Junior: tienda escolar digital de objetos reutilizados con inventario e intercambios.','En la comunidad escolar existen objetos que conservan utilidad, pero pueden quedar guardados o terminar desechados cuando su propietario ya no los necesita. Si no hay una forma visible de conocer qué está disponible y registrar los intercambios, resulta difícil que esos objetos lleguen a otra persona.

El equipo deberá investigar qué objetos podrían circular y qué información necesita un usuario para decidir un intercambio. También debe evitar que se ofrezca un objeto que ya fue entregado.','Crear un catálogo digital de objetos reutilizados con fotografía, descripción, estado y disponibilidad. Añadir un inventario sencillo y un registro de intercambios que identifique el objeto que entra o sale del catálogo.

El prototipo permitirá consultar la oferta, elegir un objeto y registrar un intercambio de prueba. Cuando se complete, su disponibilidad deberá actualizarse para que el catálogo corresponda con el inventario. El equipo registrará cuántos objetos se reutilizan y revisará si las personas comprenden el proceso. La primera versión se centrará en un conjunto manejable de objetos de la comunidad escolar.'),
(5,'A',3,'29',130,'Flujo de préstamo de materiales escolares: solicitud, registro, entrega y devolución.','Los préstamos de materiales entre equipos pueden quedar en notas dispersas o depender de la memoria. Cuando no se registra con claridad qué se prestó y cuándo debe devolverse, se dificulta localizar un material y comprobar si continúa disponible.

El equipo observará cómo se realiza un préstamo y qué pasos generan confusión. El problema que se busca resolver es la pérdida de información del proceso, para que tanto quien presta como quien recibe puedan consultar el estado del material.','Diseñar en Freeform un flujo visual que muestre, paso a paso, la solicitud, la comprobación de disponibilidad, el registro del préstamo y la devolución. Cada paso indicará qué dato se necesita y qué resultado debe quedar registrado.

Construir un prototipo visual navegable o guiado que permita simular un préstamo y seguirlo hasta su cierre. El equipo comparará el proceso actual con la propuesta, revisará qué pasos pueden simplificarse y registrará los pasos reducidos. La prueba debe demostrar que el registro permite saber si un material está prestado o disponible y reconocer qué información falta para completar una devolución.'),
(5,'A',4,'17',118,'Calculadora visual de costo, precio y ganancia para un producto escolar.','Al planificar la venta de un producto escolar, los estudiantes pueden confundir lo que cuesta elaborarlo, el precio que paga el cliente y la ganancia que queda. Esa confusión dificulta elegir un precio con fundamento y entender qué ocurre si cambian los costos o el valor de venta.

El equipo identificará qué conceptos y datos generan dudas. El reto es representar las tres cantidades de forma clara y relacionarlas con un producto concreto, para que el usuario pueda explicar el resultado de una venta.','Crear una tabla o simulador visual sencillo que separe costo, precio de venta y ganancia. El usuario introducirá los datos del producto y verá la relación ganancia = precio de venta − costo, con etiquetas y apoyos visuales fáciles de comprender.

La primera versión comparará tres escenarios de venta, como propone el banco de proyectos. Se podrá cambiar el precio y observar cómo cambia la ganancia, manteniendo visibles los datos utilizados. El equipo probará si otro estudiante interpreta correctamente cada escenario y registrará la ganancia correspondiente. Los resultados servirán para corregir etiquetas, explicaciones o cálculos antes de presentar la herramienta.'),
(5,'B',1,'44',145,'PersonalizaMe: configurador digital para pedidos de etiquetas, llaveros o útiles personalizados.','Los estudiantes y las familias pueden buscar productos que respondan a preferencias de color, nombre y diseño. Si esas elecciones se comunican de manera incompleta o en mensajes separados, el pedido puede no representar lo que el cliente quería y resultar difícil de preparar.

El equipo investigará qué opciones valoran los clientes y qué información necesita reunir un pedido personalizado. El reto es permitir que el cliente vea su elección final y que el equipo reciba una solicitud clara.','Diseñar un producto de ejemplo y un configurador visual en Freeform o Keynote, acompañado de un formulario de pedido. El cliente elegirá las opciones de personalización y revisará una representación del diseño antes de confirmar.

El pedido reunirá el tipo de producto, las opciones elegidas y la información necesaria para elaborarlo. La prueba consistirá en completar una configuración y comprobar si el diseño mostrado corresponde con lo solicitado. El equipo registrará los pedidos configurados y observará qué opciones o instrucciones generan dudas. Con esa evidencia mejorará el prototipo y la organización del proceso de personalización.'),
(5,'B',2,'6',107,'Catálogo digital de objetos perdidos por categorías para facilitar su identificación y devolución.','Un objeto perdido puede tardar en ser identificado si las personas no saben dónde consultar o deben revisar muchos objetos sin clasificar. Cuando faltan fotografías, categorías y descripciones claras, aumenta la dificultad para reconocer lo que se busca y solicitar su devolución.

El equipo investigará qué datos ayudan a identificar un objeto y cómo conviene organizarlos. El reto consiste en facilitar la búsqueda dentro de un espacio escolar definido y mantener un registro que permita conocer qué objetos ya fueron devueltos.','Crear en Pages un catálogo organizado por categorías, utilizando fotografías y descripciones breves de los objetos. Cada ficha mostrará las características que ayudan a reconocerlo y su estado dentro del proceso de devolución.

Construir un prototipo navegable en el que el usuario seleccione una categoría, consulte las fichas y localice un objeto de prueba. El procedimiento de devolución deberá estar explicado y el catálogo debe poder actualizarse cuando un objeto deje de estar disponible. El equipo registrará los objetos incorporados y devueltos, y utilizará las observaciones de los usuarios para mejorar las categorías, las imágenes y las instrucciones.'),
(5,'B',3,'23',124,'Mapa de ruido del aula: registro visual por actividad, momento y zona.','El nivel de ruido del aula cambia según la actividad y el momento de la jornada. Si solo se comenta que hay mucho ruido, sin registrar cuándo y dónde ocurre, es difícil reconocer las situaciones que requieren una mejora y comparar lo que pasa en distintos momentos.

El equipo observará las actividades del curso y definirá una forma consistente de registrar el ruido. El reto es transformar esas observaciones en información visual que permita identificar las franjas o zonas más ruidosas.','Diseñar un registro visual en Pages que relacione cada observación con su momento, actividad y zona del aula. Organizar los datos en una tabla y un gráfico sencillo por franjas, con una leyenda que explique cómo interpretar el registro.

El prototipo permitirá añadir una observación y ver cómo se incorpora al gráfico. Si se usan categorías de observación, se presentarán como tales; si se emplean mediciones, se indicarán sus unidades. El equipo identificará la franja más ruidosa y probará si otros compañeros comprenden la visualización. Después propondrá una mejora relacionada con el patrón observado y ajustará su forma de registrar los datos.'),
(5,'B',4,'28',129,'Prototipo de lectura de humedad del suelo para decidir el riego de una planta.','El riego de una planta puede decidirse por costumbre, sin una referencia visible de la humedad del suelo. Esto dificulta explicar por qué conviene regar o esperar y relacionar una condición observada con una decisión de cuidado.

El equipo investigará qué información necesita una persona para interpretar una lectura de humedad de la planta seleccionada. El reto es representar esa información de manera sencilla y permitir que el usuario practique la decisión de riego.','Construir un modelo físico de la planta o de su entorno y una pantalla conceptual en Freeform que represente lecturas de humedad. La primera versión utilizará lecturas simuladas claramente identificadas y mostrará la decisión de regar o esperar de acuerdo con el criterio definido para el prototipo.

Durante la demostración, el usuario cambiará una lectura, interpretará el indicador y elegirá una acción. El equipo observará las decisiones de riego correctas y comprobará si las etiquetas y señales se entienden. Después mejorará la representación y explicará qué información de la especie y del suelo sería necesaria para desarrollar una versión con medición real.'),
(5,'C',1,'38',139,'NoiseMap Junior: mapa de ruido escolar por lugar y momento del día.','En la comunidad escolar se perciben espacios ruidosos, pero esa percepción puede no quedar registrada con lugar y horario. Sin observaciones comparables resulta difícil señalar qué zonas requieren atención y comunicar el problema mediante un mapa comprensible.

El equipo identificará los espacios que incluirá y una manera consistente de registrar cada observación. El reto es conectar el lugar, el momento y el nivel o categoría de ruido para reconocer las zonas críticas del recorrido seleccionado.','Elaborar un mapa sencillo de los espacios elegidos y una tabla que reúna cada registro de ruido con su lugar y momento del día. Utilizar colores o símbolos acompañados de una leyenda para representar las observaciones en el mapa.

La primera versión incluirá diez registros, según el banco de proyectos. Al agregar uno nuevo, el mapa o su representación deberán actualizarse de forma comprensible. El equipo mostrará cómo se identifica una zona crítica y probará si un usuario puede interpretarla. Con los resultados ajustará los símbolos, las categorías o la organización de la información y propondrá una acción vinculada a lo observado.'),
(5,'C',2,'36',137,'WaterWatch Junior: registro semanal de hábitos de uso del agua y tendencias de ahorro.','Los hábitos cotidianos relacionados con el agua pueden comentarse sin quedar registrados de manera sencilla durante la semana. Esto dificulta identificar cuáles se repiten, reconocer oportunidades de mejora y comparar los cambios de un día a otro.

El equipo investigará qué hábitos puede observar y registrar el curso o las familias. El reto es reunir esa información con categorías claras y mostrar tendencias que ayuden a decidir una acción concreta de cuidado del agua.','Crear un formulario de registro y una tabla simple para reunir los hábitos de uso del agua durante una semana. Organizar un panel visual que muestre los registros y permita comparar los días o las categorías seleccionadas.

Durante la prueba, el usuario añadirá un registro y verá cómo se actualiza el gráfico. El equipo explicará qué representa cada dato y qué hábito propone mejorar. Se registrarán los hábitos mejorados con evidencia del seguimiento; las observaciones de hábitos no se presentarán como litros ahorrados si ese volumen no se ha medido. La prueba servirá para simplificar el formulario y mejorar la lectura del panel.'),
(5,'C',3,'43',144,'EcoCraft Market: productos de material recuperado con catálogo, precio e información de reutilización.','Un producto elaborado con material recuperado necesita comunicar para qué sirve y qué valor aporta al cliente. Si no se explica qué material se reutilizó y cómo se transformó, puede ser difícil reconocer su aporte ambiental y compararlo con su precio.

El equipo investigará qué información necesita la comunidad escolar para comprender el producto. El reto es conectar el objeto, su utilidad, su precio y el registro del material recuperado de forma clara y comprobable.','Elaborar un producto de prueba con material recuperado y una ficha digital que muestre su fotografía, función, precio y material utilizado. Vincular la ficha al objeto mediante un QR y organizar un catálogo sencillo de consulta.

Al escanear el producto, el usuario podrá ver qué material se recuperó y cómo se incorporó al diseño. El equipo registrará ese material con una unidad o descripción consistente y comprobará si el cliente comprende la utilidad del producto y su información. Con esa evidencia mejorará la presentación, la ficha y el catálogo antes de una demostración de venta.'),
(5,'C',4,'42',143,'Vivero Digital: catálogo de plantas con disponibilidad, precio, reserva y guía de cuidados.','Un vivero necesita organizar qué plantas ofrece y orientar a las personas sobre sus cuidados. Si la disponibilidad, los precios y las recomendaciones están separados, el cliente puede tener dudas al elegir o reservar y el equipo puede perder el seguimiento de los pedidos.

El equipo investigará qué necesitan consultar las familias y la comunidad antes de elegir una planta. El reto es conectar la oferta del vivero con una reserva clara y una guía de cuidados adecuada para cada planta ofrecida.','Diseñar un catálogo en Pages o Keynote con fotografía, nombre de la planta, disponibilidad, precio y recomendaciones básicas de cuidado. Incorporar un formulario o flujo de reserva que mantenga vinculados el pedido y la planta seleccionada.

El prototipo permitirá elegir una planta, consultar su guía y completar una reserva de prueba. La disponibilidad deberá revisarse para que corresponda con las plantas que se ofrecen. El equipo registrará las reservas realizadas y observará si los usuarios encuentran la información y comprenden el proceso. A partir de la prueba ajustará las fichas, las instrucciones y la organización de las reservas.')
), imported AS (
 INSERT INTO aula_private.project_source_imports(team_id,source_version,source_option,source_row,previous_title,previous_problem,previous_solution)
 SELECT t.id,'2026-10-28-v1',s.option_id,s.source_row,t.project_title,t.project_problem,t.project_solution
 FROM public.aula_teams t JOIN source s ON s.grade=t.grade AND s.parallel=t.parallel AND s.group_number=t.group_number
 ON CONFLICT(team_id,source_version) DO NOTHING RETURNING team_id
)
UPDATE public.aula_teams t SET project_title=s.title,project_problem=s.problem,project_solution=s.solution,updated_at=now()
FROM source s,imported i WHERE t.id=i.team_id AND t.grade=s.grade AND t.parallel=s.parallel AND t.group_number=s.group_number;

-- 6.º EGB: 11 proyectos asignados, separados por paralelo y grupo.
WITH source(grade,parallel,group_number,option_id,source_row,title,problem,solution) AS (VALUES
(6,'A',1,'37',188,'AccessFlow: registro de horarios y tiempos de ingreso escolar con mapa de congestión.','El ingreso escolar concentra el paso de familias y estudiantes en ciertos horarios y zonas. Si los tiempos y los puntos del recorrido no se registran de forma organizada, es difícil explicar dónde se forma la congestión y comparar las observaciones entre momentos.

El equipo delimitará qué parte del acceso observará y cómo registrará los horarios y tiempos. El problema que busca resolver es la falta de una vista conjunta de esos datos para reconocer las franjas más congestionadas.','Construir una web con un formulario de registro, un mapa sencillo de los puntos observados y un panel de resultados. Cada registro asociará el horario y el tiempo de ingreso con el punto del acceso correspondiente.

La primera versión permitirá introducir los tiempos de una prueba y visualizar la franja más congestionada; la demostración del banco propone registrar cinco tiempos. El equipo mostrará el tiempo promedio y la relación con las zonas del mapa, explicando cómo calculó los resultados. Con la prueba revisará si los usuarios interpretan correctamente el panel y utilizará esa evidencia para mejorar el registro y la presentación de los datos.'),
(6,'A',2,'35',186,'BioVision Growth: comparación de fotografías y medidas del crecimiento de una planta.','El crecimiento de una planta puede observarse sin documentar de manera continua sus cambios. Si las fotografías, fechas y medidas no quedan reunidas, se dificulta comparar semanas, reconocer una evolución visible y explicar qué necesita seguimiento.

El equipo elegirá una planta y una forma consistente de registrar sus observaciones. El reto es transformar las fotografías y medidas en una secuencia que permita ver el crecimiento y consultar cómo ha cambiado a lo largo del tiempo.','Desarrollar una web con ficha de la planta, registro de fotografías y medidas, y una línea temporal. Cada evidencia debe conservar su fecha y el mismo criterio de observación para que las comparaciones sean comprensibles.

El prototipo incluirá un comparador que permita seleccionar dos registros y mostrar el cambio observado. El equipo utilizará las medidas para describir el crecimiento semanal y señalar los cambios visibles que requieran seguimiento. Durante la prueba comprobará si un usuario encuentra el historial y entiende la comparación. Con esa evidencia ajustará el registro, las etiquetas y la organización de la línea temporal.'),
(6,'A',3,'6',157,'ActaPro Lite: web para convertir notas de reuniones en acuerdos, responsables y fechas.','Las notas de una reunión pueden conservar lo que se conversó sin dejar claras las acciones que deben realizarse después. Cuando faltan acuerdos concretos, responsables y fechas, los equipos o docentes pueden tener dificultades para dar seguimiento a lo decidido.

El equipo investigará cómo se registran actualmente las reuniones y qué información suele quedar pendiente. El reto es organizar las notas en un acta que permita reconocer qué se hará, quién lo hará y para cuándo.','Crear una web con formulario de notas y una plantilla de acta que ordene los acuerdos, responsables y fechas. La automatización será sencilla y visible: el usuario revisará los campos y confirmará que el acta representa lo acordado.

El prototipo permitirá ingresar notas de prueba y generar un acta consultable con sus acciones. El equipo comparará el tiempo empleado al elaborar un acta con el proceso actual y con la propuesta, registrando los minutos ahorrados cuando disponga de ambas mediciones. También comprobará si los usuarios comprenden los acuerdos y detectan información incompleta, para mejorar la plantilla y el flujo de revisión.'),
(6,'A',4,'16',167,'PatternWatch: registro de incidencias escolares y filtros para identificar recurrencias.','Una incidencia escolar puede repetirse sin que los registros permitan reconocer con claridad el lugar, la fecha o el tipo de situación. Si esa información queda dispersa, es difícil identificar un patrón y explicar qué punto o momento requiere intervención.

El equipo delimitará las categorías y los datos que utilizará en el prototipo. El reto es relacionar los registros para mostrar recurrencias de manera comprensible y sustentar una propuesta de mejora con evidencia.','Desarrollar una web con un conjunto de datos y un panel que permita filtrar incidencias por fecha, lugar y tipo. Las categorías y la forma de contar los registros deberán estar explicadas para que el usuario interprete correctamente el resultado.

La demostración permitirá aplicar filtros y revelar el patrón más recurrente. El equipo mostrará qué registros lo sustentan y cómo cambia el resultado al variar el filtro. Probará la navegación con usuarios de coordinación o un usuario representativo y registrará qué información encuentran con facilidad. A partir de la prueba ajustará los filtros, los gráficos y las explicaciones del panel.'),
(6,'A',5,'18',169,'AccessflowTracker Web: análisis de tiempos y puntos críticos de congestión en la entrada escolar.','La congestión en la entrada escolar puede variar según el horario, el día y el punto observado. Sin registros comparables de tiempos y ubicaciones, resulta difícil identificar cuál es la combinación más crítica y valorar si un cambio mejora el ingreso.

El equipo seleccionará una franja y una zona del acceso principal para delimitar su observación. El reto es analizar esos registros y mostrar el punto o momento que concentra el mayor problema, con los datos que justifican esa conclusión.','Crear un registro de tiempos y un dashboard web que permita consultar la congestión por día, franja y punto del acceso. El panel destacará la franja y el punto críticos de acuerdo con los registros disponibles.

El prototipo permitirá seleccionar un día y comparar sus resultados con los de otras observaciones del mismo ámbito. El equipo explicará qué representa el tiempo de ingreso y cómo identifica un punto crítico. La prueba recogerá si los usuarios comprenden los filtros y reconocen dónde se concentra el problema. Esos resultados servirán para proponer una acción y planificar una nueva observación que permita comparar el antes y el después.'),
(6,'B',1,'33',184,'EnergyPulse: dashboard de hábitos energéticos por aula y horario con acciones de ahorro.','La institución puede no visualizar de forma conjunta qué hábitos de uso de energía se repiten en cada aula y horario. Sin un registro organizado, es difícil reconocer usos innecesarios y decidir qué acción de ahorro conviene priorizar.

El equipo investigará qué hábitos puede observar y qué datos necesita para compararlos. El reto es mostrar los horarios y hábitos críticos en un panel comprensible, distinguiendo observaciones de uso y estimaciones de consumo.','Desarrollar un dashboard web con registros de hábitos energéticos, filtros por aula y horario, y recomendaciones relacionadas con los patrones encontrados. La primera versión podrá usar datos de muestra claramente identificados, como propone el banco.

Al añadir un registro, el sistema actualizará el panel y permitirá identificar el horario con mayor concentración del hábito analizado. Las recomendaciones indicarán qué dato las sustenta. Si se calcula consumo o ahorro estimado, se explicará el supuesto utilizado. El equipo probará si los usuarios entienden los filtros y las recomendaciones, y registrará los hábitos críticos detectados para mejorar el prototipo.'),
(6,'B',2,'24',175,'CircularMarket Web: publicación de objetos e historial de intercambios de la comunidad escolar.','Los objetos que todavía son útiles pueden dejar de circular cuando no existe un medio organizado para ofrecerlos y registrar su intercambio. La comunidad puede desconocer lo disponible o no saber si un objeto ya fue entregado.

El equipo investigará qué necesita una persona para publicar, buscar y solicitar un objeto. El reto es conectar la oferta con un proceso de intercambio y mantener un historial que permita comprobar qué objetos se han reutilizado.','Construir una web de publicación e intercambio con fichas de objetos, disponibilidad y un historial de movimientos. El usuario podrá consultar una ficha, iniciar una solicitud y seguir un flujo de intercambio claramente definido.

El MVP permitirá publicar un objeto de ejemplo, simular su intercambio y actualizar su estado. El equipo mostrará el registro que queda después de la operación y cómo se cuenta un objeto intercambiado. Probará si los usuarios entienden la navegación y distinguen lo disponible de lo entregado. Con esa evidencia mejorará las fichas, las instrucciones y la trazabilidad del proceso.'),
(6,'B',3,'41',192,'Smart Snack Business: configurador web de snacks con precio e información nutricional básica.','Un emprendimiento de snacks puede necesitar atender preferencias distintas y explicar qué incluye cada pedido. Si las combinaciones, sus precios y la información de composición están separados, el cliente puede tener dudas al elegir y el equipo puede perder claridad sobre lo que debe preparar.

El equipo investigará qué combinaciones interesan a estudiantes y familias. El reto es mostrar de forma coherente la selección, su precio y la información nutricional básica registrada para los productos del catálogo.','Desarrollar un producto de ejemplo y una web en la que el cliente arme un combo a partir del catálogo. El precio y la información nutricional básica se actualizarán según los componentes seleccionados, usando datos identificables de los productos ofrecidos.

El MVP permitirá revisar y registrar un pedido completo. El equipo probará que el cálculo corresponda con la selección y que el cliente comprenda qué recibirá. Registrará pedidos y ticket promedio cuando existan datos suficientes para calcularlo. Las observaciones de la prueba servirán para mejorar el catálogo, el resumen del pedido y la forma de presentar los precios y la composición.'),
(6,'B',4,'1',152,'BioTrack: historial web de fotografías y cuidados de tres especies de la Zoobotánica.','Los cuidados de las especies de la Zoobotánica pueden quedar anotados en lugares distintos o sin una relación visible con la fecha y la evidencia. Esto dificulta consultar el historial de una especie y reconocer qué tareas están cumplidas o pendientes.

El equipo seleccionará tres especies y definirá qué información necesita registrar de cada una. El reto es reunir los datos para que una persona responsable pueda encontrar el cuidado realizado y dar continuidad al seguimiento.','Crear una web navegable con ficha de cada especie, fotografía, fecha y registro de cuidados. El historial deberá permitir consultar la evolución y distinguir tareas pendientes de las ya realizadas.

La primera versión partirá de un wireframe y una base de datos simple para las tres especies seleccionadas. En la demostración, el usuario elegirá una especie y consultará su historial. El equipo registrará la cantidad de registros por especie y comprobará si el usuario localiza la información y entiende el estado de las tareas. Con esa evidencia mejorará las fichas y el flujo de actualización de cuidados.'),
(6,'B',5,'28',179,'EmergencyDecision Web: escenarios interactivos para practicar decisiones en una emergencia.','Los estudiantes pueden recordar un protocolo sin haber practicado cómo elegir una acción dentro de una situación concreta. Esa diferencia dificulta reconocer qué decisión corresponde y comprender sus consecuencias antes de una emergencia real.

El equipo seleccionará un escenario delimitado y organizará las decisiones que necesita practicar el usuario. El reto es convertir un protocolo en una experiencia interactiva que permita explicar y revisar las elecciones realizadas.','Construir un árbol de decisiones y una web de escenarios interactivos. En cada situación se presentarán opciones de acción y una consecuencia explicada, basadas en el protocolo seleccionado y revisado con la docente.

El MVP permitirá recorrer el escenario, elegir una acción y comprender por qué resulta adecuada o qué debe corregirse. El equipo registrará las decisiones correctas dentro de la simulación y observará qué instrucciones generan confusión. La prueba servirá para mejorar la secuencia, las opciones y la retroalimentación. La demostración se realizará como una práctica guiada del escenario propuesto.'),
(6,'B',6,'4',155,'FoodwasteDashboard Web: desperdicio alimentario del comedor por tipo de alimento y día.','En el comedor, los registros de desperdicio pueden no mostrar con claridad qué tipos de alimento se repiten y en qué días. Sin esa comparación es difícil reconocer patrones y proponer una acción relacionada con el origen del desperdicio.

El equipo delimitará cómo clasificará los alimentos y qué unidad o criterio utilizará en cada registro. El reto es transformar esos datos en información que permita identificar la categoría y el día críticos del conjunto observado.','Desarrollar un dashboard web con un conjunto pequeño de datos del comedor, clasificados por tipo de alimento y día. Cada registro utilizará un criterio consistente para que los resultados puedan compararse.

El prototipo permitirá filtrar los datos y revelar la categoría y el día con mayor desperdicio registrado. El equipo explicará qué muestra cada gráfico y qué acción propone a partir del patrón encontrado. La prueba comprobará si el usuario identifica correctamente los puntos críticos. Después se ajustarán categorías, filtros o visualizaciones y se definirá cómo observar si la acción propuesta modifica el patrón.')
), imported AS (
 INSERT INTO aula_private.project_source_imports(team_id,source_version,source_option,source_row,previous_title,previous_problem,previous_solution)
 SELECT t.id,'2026-10-28-v1',s.option_id,s.source_row,t.project_title,t.project_problem,t.project_solution
 FROM public.aula_teams t JOIN source s ON s.grade=t.grade AND s.parallel=t.parallel AND s.group_number=t.group_number
 ON CONFLICT(team_id,source_version) DO NOTHING RETURNING team_id
)
UPDATE public.aula_teams t SET project_title=s.title,project_problem=s.problem,project_solution=s.solution,updated_at=now()
FROM source s,imported i WHERE t.id=i.team_id AND t.grade=s.grade AND t.parallel=s.parallel AND t.group_number=s.group_number;

-- 7.º EGB: 10 proyectos asignados, separados por paralelo y grupo.
WITH source(grade,parallel,group_number,option_id,source_row,title,problem,solution) AS (VALUES
(7,'A',1,'54',255,'MetaStartup Expo: feria virtual de emprendimientos con stands, pitch, votación y métricas.','Las ferias presenciales tienen un tiempo y un espacio limitados para que visitantes, familias y jurados conozcan los proyectos. Además, el equipo puede recibir comentarios dispersos sin datos claros sobre qué stand despertó interés o qué parte de la propuesta necesita mejorar.

El reto es ampliar la experiencia de visita y relacionar las interacciones con evidencias útiles para cada emprendimiento. El equipo deberá identificar qué necesita consultar el visitante y qué información ayudará al emprendedor a mejorar su presentación.','Desarrollar una feria virtual con stands digitales donde cada equipo presente su pitch, prototipo y propuesta. El visitante podrá recorrer los stands, consultar el contenido, votar y dejar retroalimentación; un dashboard reunirá visitas, votos y comentarios.

El prototipo inicial representará una feria con tres stands y el MVP buscará integrar cinco, de acuerdo con el banco. La validación comprobará el recorrido del visitante, el registro de su interacción y la actualización de las métricas. El equipo analizará visitas por stand, votos y feedback para explicar qué genera interés y qué debe mejorar. La demostración mostrará cómo una votación cambia el ranking o el mapa de interés.'),
(7,'A',2,'52',253,'Immersive Pitch Arena: simulación inmersiva para entrenar el pitch y responder preguntas de una audiencia.','Los equipos emprendedores pueden practicar su pitch en un contexto poco parecido al de una feria, un jurado o una presentación ante posibles clientes. Si la práctica ofrece poca retroalimentación, resulta difícil detectar qué explicación, evidencia o respuesta necesita mejorar antes de la presentación importante.

El reto es crear un entorno de ensayo que presente situaciones comprensibles y permita comparar intentos. El equipo debe definir qué necesita practicar el expositor y cómo recoger una evaluación útil de su desempeño.','Usar el aula inmersiva como escenario de práctica del pitch, con recursos visuales que representen una feria o una audiencia de inversionistas. El equipo cargará su proyecto, elegirá el escenario y realizará la presentación mientras aparecen preguntas o situaciones que debe responder.

El MVP integrará dos escenarios, preguntas sorpresa y una evaluación recogida con QR, formularios o una tabla de registro. Podrá utilizar Keynote o HTML para la experiencia y asistencia de IA cuando aporte al diseño de preguntas. La validación comparará el puntaje y las mejoras entre el primer y el segundo intento. La demostración incluirá una pregunta inesperada y mostrará cómo el equipo responde con evidencia de su proyecto.'),
(7,'A',3,'25',226,'ServicePrice AI: cotizador web de servicios estudiantiles con tiempo, costos y margen.','Un servicio estudiantil puede fijar su precio sin considerar el tiempo requerido y los costos que implica realizarlo. Esto dificulta justificar una cotización, comparar encargos y reconocer si el precio propuesto deja un margen adecuado.

El equipo investigará qué datos necesita un emprendedor escolar para cotizar un servicio concreto. El reto es relacionar tiempo, costos y precio de forma transparente y permitir que el usuario explore cómo cambia el resultado en distintos escenarios.','Construir un modelo de costos y un cotizador web en el que el usuario ingrese el tiempo de trabajo y los costos del servicio. El sistema generará una cotización y mostrará el margen correspondiente, junto con los datos y supuestos utilizados.

El MVP permitirá cambiar horas o costos y comparar el resultado de los escenarios. La asistencia de IA será conceptual o se incorporará cuando ayude a explicar la cotización, manteniendo visibles los cálculos. El equipo validará si usuarios emprendedores comprenden el precio y detectan datos faltantes. Usará el margen por servicio y la retroalimentación para ajustar el modelo y la presentación del cotizador.'),
(7,'A',4,'36',237,'BioTwin Zoobotánica: gemelo digital de una zona con especies, cuidados, variables e incidencias.','La información sobre especies, cuidados y condiciones de una zona de la Zoobotánica puede quedar distribuida en fichas y registros separados. Esa dispersión dificulta comprender la zona como un sistema y relacionar una variable ambiental o una incidencia con las especies que necesitan atención.

El equipo delimitará una zona y los datos que representará. El reto es reunirlos en una vista navegable que permita explorar su relación y explicar qué requiere seguimiento, sin presentar la simulación como una réplica completa del espacio real.','Desarrollar un mapa digital simplificado de la zona, con fichas de especies, cuidados, variables ambientales e incidencias. La navegación permitirá elegir un punto o una especie y consultar su información, conservando la relación con el conjunto.

El MVP incorporará datos y una simulación sencilla que muestre cómo un cambio de variable puede señalar una especie que requiere atención. El equipo explicará el criterio que utiliza esa señal. Validará la navegación con responsables o visitantes representativos y registrará incidencias y cuidados para evaluar si la vista facilita el seguimiento. Con esa evidencia mejorará el mapa, las fichas y la explicación de las relaciones del sistema.'),
(7,'A',5,'41',242,'Smart Cafeteria: menú configurable, información nutricional, reservas y dashboard de demanda.','La cafetería escolar puede tener dificultades para relacionar los pedidos con la información del menú y los horarios de mayor demanda. Si cada dato se gestiona por separado, los usuarios pueden esperar más tiempo o decidir con información incompleta, y el equipo pierde una vista conjunta de lo que se solicita.

El reto es integrar la elección del menú, la reserva y el registro de demanda para mejorar la experiencia del usuario. El equipo deberá investigar cómo se realizan los pedidos y qué información necesitan estudiantes y familias para elegir.','Construir una web donde el usuario arme un menú, compare la información nutricional básica registrada y realice una reserva. El pedido deberá conservar su selección y el horario correspondiente; un dashboard mostrará la demanda a partir de esas reservas.

El MVP conectará el menú y la reserva con la actualización del panel. La prueba permitirá armar una selección, confirmarla y comprobar qué cambia en los datos de demanda. El equipo registrará los tiempos de espera o del proceso cuando se midan y analizará la distribución de pedidos por horario. Con esa evidencia revisará el flujo de compra, la presentación del menú y la utilidad del dashboard.'),
(7,'B',1,'46',247,'Smart EcoTour: recorrido por la Zoobotánica con estaciones QR, retos y evidencias de aprendizaje.','La visita a la Zoobotánica puede quedar desconectada de los recursos digitales y de un seguimiento organizado del recorrido. Los estudiantes observan las especies, pero pueden no contar con un sistema que reúna información, retos, estaciones visitadas y evidencias de aprendizaje.

Esto dificulta reconocer qué partes del recorrido se completaron y aprovechar cada visita como una experiencia interactiva. El reto es conectar las estaciones físicas con contenidos y acciones que ayuden al visitante a aprender y permitan al equipo revisar el recorrido.','Diseñar una ruta con estaciones físicas conectadas a una web mediante QR. Al escanear una estación, el visitante abrirá información de la especie, un reto y un espacio para registrar la evidencia de su participación.

El MVP integrará cinco estaciones y permitirá consultar cuáles se han completado. La experiencia utilizará la gamificación para guiar el recorrido y mantener relacionadas la ubicación, el contenido y la actividad. El equipo validará si los visitantes encuentran cada estación, comprenden el reto y registran su avance. Analizará las estaciones completadas y la retroalimentación para mejorar las instrucciones, los contenidos y la continuidad de la ruta.'),
(7,'B',2,'16',217,'FocusflowPrevenir AI: planificador web para visualizar carga académica semanal y simular redistribuciones.','Los estudiantes pueden acumular tareas sin visualizar cómo se distribuye su carga durante la semana. Si solo consultan pendientes aislados, resulta difícil identificar días con demasiadas actividades y anticipar una organización más equilibrada.

El equipo investigará cómo registran sus tareas los usuarios y qué criterio les ayuda a estimar la carga de cada día. El reto es mostrar ese balance y ofrecer una redistribución comprensible que el estudiante pueda revisar antes de adoptarla.','Desarrollar una agenda web que registre tareas por día y represente la carga semanal con un criterio explícito. El usuario podrá agregar una tarea y observar cómo cambia el balance del panel.

El MVP propondrá alternativas de redistribución mediante reglas o una asistencia de IA conceptual que aporte al objetivo. Las propuestas deberán explicar qué cambia y permitir que el usuario decida. El equipo validará la claridad del registro y la utilidad de las alternativas con estudiantes. Comparará los días de sobrecarga según el criterio definido y utilizará las observaciones para mejorar la visualización y las recomendaciones.'),
(7,'B',3,'7',208,'HabitatGuard AI: auditoría integrada de un hábitat animal con criterios, semáforo y prioridades.','Las condiciones de un hábitat animal pueden revisarse por separado, sin una vista integrada que ayude a priorizar qué necesita atención. Temperatura, humedad, limpieza, agua y elementos como el refugio pueden quedar en registros desconectados y dificultar el seguimiento de una condición pendiente.

El reto es reunir esos criterios en una auditoría específica del hábitat y mostrar qué requiere revisión. El equipo debe definir con la docente o responsable los criterios aplicables a la especie y cómo se interpretarán los datos.','Crear un checklist y un panel de cinco criterios para el hábitat seleccionado. El sistema reunirá lecturas o registros de observación y mostrará un semáforo, una prioridad de revisión y un historial de auditorías.

El MVP integrará el panel, el registro de cada auditoría y las alertas según reglas explicadas. En la demostración se cambiará una lectura o un criterio y se mostrará cómo se recalcula la prioridad. El equipo validará si los responsables comprenden las señales y pueden consultar el historial. Registrará criterios adecuados y alertas por hábitat para mejorar las reglas y la presentación de la información.'),
(7,'B',4,'15',216,'CircularHarvest Audit: trazabilidad poscosecha y porcentaje de aprovechamiento de la producción.','Después de la cosecha puede no quedar registrado cuánto producto se utiliza, vende, transforma, composta o desperdicia. Sin un registro del destino y una cantidad comparable, es difícil medir el aprovechamiento y relacionarlo con decisiones de emprendimiento y economía circular.

El reto es dar seguimiento a lo que ocurre después de cosechar y representar los resultados con claridad. El equipo deberá acordar cómo clasificar los destinos y qué unidad utilizará para que los porcentajes correspondan con el total registrado.','Desarrollar un registro poscosecha que asocie cada producto y cantidad con su destino: uso, venta, transformación, compostaje o desperdicio. Un dashboard mostrará la distribución y calculará los porcentajes de aprovechamiento y desperdicio a partir de los registros.

El MVP permitirá agregar un destino y ver la actualización del panel. El equipo explicará qué destinos considera aprovechamiento y cómo calcula los porcentajes, evitando contar una misma cantidad dos veces. Validará la utilidad del registro con responsables de cosecha o emprendimiento y comparará resultados para proponer mejoras. La demostración mostrará la trazabilidad de una cosecha y el efecto de cada registro en el indicador.'),
(7,'B',5,'27',228,'ZooMicroclimate AI: análisis de temperatura y humedad para seguimiento del cuidado de especies.','Las condiciones de temperatura y humedad pueden variar dentro de la Zoobotánica y afectar los cuidados de las especies. Si los registros no se relacionan con el espacio, el momento y la especie seleccionada, resulta difícil reconocer un patrón y explicar cuándo conviene revisar una condición.

El reto es analizar esos microclimas y transformar los datos en información útil para el seguimiento. El equipo deberá definir con la docente o responsable qué criterios aplicará y qué recomendaciones puede sustentar con los datos disponibles.','Construir un conjunto de datos de temperatura y humedad y una web que permita seleccionar una especie para consultar sus condiciones. El sistema identificará patrones y mostrará alertas o sugerencias de revisión mediante reglas explicadas o asistencia de IA conceptual cuando aporte valor.

El MVP deberá conectar la selección de especie con los datos y las condiciones que justifican la señal. El equipo validará si los usuarios comprenden por qué se muestra una alerta y qué revisión propone. Registrará alertas y cuidados para comparar la utilidad del seguimiento y ajustar el panel. La demostración permitirá cambiar los datos o la especie y observar la actualización de la condición mostrada.')
), imported AS (
 INSERT INTO aula_private.project_source_imports(team_id,source_version,source_option,source_row,previous_title,previous_problem,previous_solution)
 SELECT t.id,'2026-10-28-v1',s.option_id,s.source_row,t.project_title,t.project_problem,t.project_solution
 FROM public.aula_teams t JOIN source s ON s.grade=t.grade AND s.parallel=t.parallel AND s.group_number=t.group_number
 ON CONFLICT(team_id,source_version) DO NOTHING RETURNING team_id
)
UPDATE public.aula_teams t SET project_title=s.title,project_problem=s.problem,project_solution=s.solution,updated_at=now()
FROM source s,imported i WHERE t.id=i.team_id AND t.grade=s.grade AND t.parallel=s.parallel AND t.group_number=s.group_number;

CREATE OR REPLACE FUNCTION public.aula_student_snapshot()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); t public.aula_teams; m public.aula_members; p public.aula_publications; result jsonb;
BEGIN
 IF tid IS NULL THEN RETURN jsonb_build_object('status','no_enrollment'); END IF;
 SELECT * INTO t FROM public.aula_teams WHERE id=tid;
 SELECT mm.* INTO m FROM public.aula_members mm JOIN public.aula_enrollments e ON e.member_id=mm.id WHERE e.auth_user_id=auth.uid();
 SELECT * INTO p FROM public.aula_publications WHERE grade=t.grade AND parallel=t.parallel AND week_number=8 AND state IN('available','closed');
 SELECT jsonb_build_object('status','ok','user',jsonb_build_object('grade',t.grade,'parallel',t.parallel,'group',t.group_number,'name',m.full_name,'givenName',aula_private.partes_nombre(m.full_name)->>'nombres'),
 'team',jsonb_build_object('name',t.team_name,'color',t.color_hex,'colorName',t.color_name,
 'project',jsonb_build_object('title',t.project_title,'official',t.project_description,'problem',coalesce(to_jsonb(t)->>'project_problem',''),'solution',coalesce(to_jsonb(t)->>'project_solution',''),'updatedAt',t.updated_at,'editable',true),
 'members',coalesce((SELECT jsonb_agg(jsonb_build_object('name',full_name,'role',role_name) ORDER BY
 CASE role_name WHEN 'Líder' THEN 1 WHEN 'Secretario' THEN 2 WHEN 'Secretario/a' THEN 2 WHEN 'Investigador' THEN 3 WHEN 'Investigador/a' THEN 3 WHEN 'Diseñador' THEN 4 WHEN 'Diseñador/a' THEN 4 ELSE 5 END,full_name)
 FROM public.aula_members WHERE team_id=tid AND active),'[]'::jsonb)),
 'publication',CASE WHEN p.id IS NULL THEN NULL ELSE jsonb_build_object('id',p.id,'title',p.title,'instructions',p.instructions,'state',p.state) END,
 'work',CASE WHEN p.id IS NULL THEN NULL ELSE (SELECT jsonb_build_object('content',content,'status',status,'savedAt',updated_at,'submittedAt',submitted_at) FROM public.aula_works WHERE team_id=tid AND publication_id=p.id) END,
 'portfolio',(SELECT jsonb_build_object('url',shared_url,'app',app,'updatedAt',updated_at) FROM public.aula_portfolios WHERE team_id=tid)) INTO result;
 RETURN result;
END; $$;


CREATE OR REPLACE FUNCTION public.aula_student_save_project(p_title text,p_problem text,p_solution text,p_team_name text,p_expected_updated_at timestamptz)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); current_team public.aula_teams;
BEGIN
 IF tid IS NULL THEN RAISE EXCEPTION 'Tu registro ya no pertenece a un equipo activo'; END IF;
 IF p_title IS NULL OR p_problem IS NULL OR p_solution IS NULL OR p_team_name IS NULL
 OR char_length(btrim(p_title)) NOT BETWEEN 3 AND 500 OR char_length(p_problem)>2000 OR char_length(p_solution)>3000 OR char_length(p_team_name)>120 THEN
 RAISE EXCEPTION 'Revisa el tema, problema, solución y nombre del equipo'; END IF;
 SELECT * INTO current_team FROM public.aula_teams WHERE id=tid FOR UPDATE;
 IF p_expected_updated_at IS NULL OR current_team.updated_at<>p_expected_updated_at THEN
 RAISE EXCEPTION 'El proyecto cambió mientras lo editabas. Pulsa Actualizar equipo y revisa los datos antes de guardar.' USING ERRCODE='40001'; END IF;
 IF aula_private.equipo_estudiante() IS DISTINCT FROM tid THEN RAISE EXCEPTION 'Tu equipo cambió. Vuelve a ingresar'; END IF;
 UPDATE public.aula_teams SET project_title=btrim(p_title),project_problem=btrim(p_problem),project_solution=btrim(p_solution),team_name=btrim(p_team_name),updated_at=now() WHERE id=tid;
 RETURN public.aula_student_snapshot();
END; $$;
REVOKE ALL ON FUNCTION public.aula_student_save_project(text,text,text,text,timestamptz),public.aula_student_snapshot() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_student_save_project(text,text,text,text,timestamptz),public.aula_student_snapshot() TO authenticated;
COMMIT;
SELECT t.grade AS curso,t.parallel AS paralelo,count(*) AS proyectos_cargados
FROM aula_private.project_source_imports i JOIN public.aula_teams t ON t.id=i.team_id WHERE i.source_version='2026-10-28-v1'
GROUP BY t.grade,t.parallel ORDER BY t.grade,t.parallel;
