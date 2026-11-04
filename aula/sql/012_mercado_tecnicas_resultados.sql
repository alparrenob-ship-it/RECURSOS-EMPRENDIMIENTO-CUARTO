BEGIN;
CREATE OR REPLACE FUNCTION public.aula_market_v2_snapshot(p_team uuid DEFAULT NULL,p_grade integer DEFAULT 7)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE teacher boolean:=public.aula_is_teacher(); tid uuid; t public.aula_teams; p public.aula_publications; w public.aula_works; result jsonb;
BEGIN
 IF teacher THEN
  IF p_team IS NULL THEN RETURN jsonb_build_object('teacher',true,'teams',(SELECT jsonb_agg(jsonb_build_object('id',id,'grade',grade,'parallel',parallel,'group',group_number,'title',project_title) ORDER BY parallel,group_number) FROM public.aula_teams WHERE grade=p_grade AND grade IN(5,6,7))); END IF;
  tid:=p_team;
 ELSE
  tid:=aula_private.equipo_estudiante();
  IF tid IS NULL OR p_team IS NOT NULL THEN RAISE EXCEPTION 'Ingresa con tu equipo'; END IF;
 END IF;
 SELECT * INTO t FROM public.aula_teams WHERE id=tid AND grade IN(5,6,7);
 IF NOT FOUND THEN RAISE EXCEPTION 'Actividad de quinto a séptimo'; END IF;
 SELECT * INTO p FROM public.aula_publications WHERE grade=t.grade AND parallel=t.parallel AND week_number=9;
 IF p.id IS NULL OR (NOT teacher AND p.state='draft') THEN RAISE EXCEPTION 'Tu docente todavía no habilitó esta actividad'; END IF;
 SELECT * INTO w FROM public.aula_works WHERE team_id=tid AND publication_id=p.id;
 result:=jsonb_build_object('teacher',teacher,'team',jsonb_build_object('id',t.id,'grade',t.grade,'parallel',t.parallel,'group',t.group_number,'name',t.team_name,'title',t.project_title,'problem',t.project_problem,'solution',t.project_solution),
 'members',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'name',full_name,'role',role_name) ORDER BY full_name),'[]'::jsonb) FROM public.aula_members WHERE team_id=tid AND active),
 'publication',jsonb_build_object('id',p.id,'state',p.state),'work',jsonb_build_object('content',coalesce(w.content,'{}'::jsonb),'version',w.updated_at,'status',coalesce(w.status,'draft')),
 'responses',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'kind',kind,'technique',technique,'instrument',instrument,'answers',answers,'at',created_at) ORDER BY created_at),'[]'::jsonb) FROM aula_private.market_responses WHERE team_id=tid));
 IF teacher THEN
  result:=result||jsonb_build_object('contributions',(SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) FROM (SELECT DISTINCT ON(c.field_key) c.field_key,m.full_name AS name,c.member_id,c.created_at FROM aula_private.market_contributions c JOIN public.aula_members m ON m.id=c.member_id WHERE c.team_id=tid ORDER BY c.field_key,c.created_at DESC,c.id DESC)x),
  'participation',(SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) FROM (SELECT m.id,m.full_name AS name,count(c.id) AS contributions FROM public.aula_members m LEFT JOIN aula_private.market_contributions c ON c.member_id=m.id AND c.team_id=tid WHERE m.team_id=tid AND m.active GROUP BY m.id,m.full_name)x),
  'evaluation',(SELECT to_jsonb(e) FROM public.aula_evaluations e WHERE e.team_id=tid AND e.publication_id=p.id));
 END IF;
 RETURN result;
END; $$;


CREATE OR REPLACE FUNCTION public.aula_market_v2_save(p_member uuid,p_changes jsonb,p_expected timestamptz,p_submit boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); p public.aula_publications; w public.aula_works; item record; c jsonb; k text; i integer; g integer; n integer:=0; stamp timestamptz:=clock_timestamp(); tech text; qty integer;
BEGIN
 SELECT grade INTO g FROM public.aula_teams WHERE id=tid AND grade IN(5,6,7);
 IF g IS NULL THEN RAISE EXCEPTION 'Ingresa con tu equipo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.aula_members WHERE id=p_member AND team_id=tid AND active) THEN RAISE EXCEPTION 'Selecciona un integrante activo de tu equipo'; END IF;
 SELECT pp.* INTO p FROM public.aula_publications pp JOIN public.aula_teams t ON t.grade=pp.grade AND t.parallel=pp.parallel WHERE t.id=tid AND pp.week_number=9;
 IF p.state IS DISTINCT FROM 'available' THEN RAISE EXCEPTION 'La actividad está cerrada'; END IF;
 IF jsonb_typeof(p_changes) IS DISTINCT FROM 'object' OR octet_length(p_changes::text)>1800000 THEN RAISE EXCEPTION 'Revisa los campos e imágenes'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(tid::text,9));
 SELECT * INTO w FROM public.aula_works WHERE team_id=tid AND publication_id=p.id FOR UPDATE;
 IF w.updated_at IS DISTINCT FROM p_expected THEN RAISE EXCEPTION 'Otro integrante guardó cambios. Actualiza para revisarlos; tu borrador se conserva.' USING ERRCODE='40001'; END IF;
 c:=coalesce(w.content,'{}'::jsonb);
 FOR item IN SELECT * FROM jsonb_each(p_changes) LOOP
  k:=item.key;
  IF k!~'^(audience[0-3]_(image|name)|need|user|buyer|technique|q[0-7]_(text|a|b|c|why)|interview[0-3]|interview_target|interview_media|empathy_(target|think|hear|see|do|basis|place|date)|analysis_[a-f0-9]{16})$' OR jsonb_typeof(item.value)<>'string' THEN RAISE EXCEPTION 'Campo no permitido'; END IF;
  IF k~'_image$' THEN
   IF char_length(item.value#>>'{}')>320000 OR ((item.value#>>'{}')<>'' AND (item.value#>>'{}')!~'^data:image/jpeg;base64,[A-Za-z0-9+/=]+$') THEN RAISE EXCEPTION 'Usa una imagen JPG preparada por el selector'; END IF;
  ELSIF char_length(item.value#>>'{}')>2000 THEN RAISE EXCEPTION 'Máximo 2000 caracteres por campo'; END IF;
  IF g<7 AND (k~'^(interview|empathy_)' OR (g=5 AND k~'^q[5-7]_') OR (g=6 AND k~'^q[6-7]_')) THEN RAISE EXCEPTION 'Campo no disponible para este grado'; END IF;
  IF k='interview_media' AND (item.value#>>'{}')<>'' AND (item.value#>>'{}')!~'^https://[^[:space:]<>]+$' THEN RAISE EXCEPTION 'Pega un enlace HTTPS válido'; END IF;
  c:=jsonb_set(c,ARRAY[k],item.value,true);
 END LOOP;
 IF g<7 THEN c:=c||'{"technique":"encuesta"}'::jsonb; END IF;
 tech:=c->>'technique';
 IF tech IS NOT NULL AND tech NOT IN('encuesta','entrevista','observacion') THEN RAISE EXCEPTION 'Selecciona una técnica válida'; END IF;
 IF p_submit THEN
  IF (SELECT project_title FROM public.aula_teams WHERE id=tid)~*'tema por (definir|confirmar)' THEN RAISE EXCEPTION 'Confirmen primero el tema de su proyecto con la docente'; END IF;
  FOR i IN 0..3 LOOP
   IF btrim(coalesce(c->>('audience'||i||'_name'),''))<>'' AND coalesce(c->>('audience'||i||'_image'),'')<>'' THEN n:=n+1;
   ELSIF btrim(coalesce(c->>('audience'||i||'_name'),''))<>'' OR coalesce(c->>('audience'||i||'_image'),'')<>'' THEN RAISE EXCEPTION 'Completa imagen y nombre de cada público utilizado'; END IF;
  END LOOP;
  IF n=0 THEN RAISE EXCEPTION 'Completa al menos un público con su imagen'; END IF;
  IF g=7 THEN FOREACH k IN ARRAY ARRAY['need','user','buyer'] LOOP IF btrim(coalesce(c->>k,''))='' THEN RAISE EXCEPTION 'Completa necesidad, usuario y comprador'; END IF; END LOOP; END IF;
  IF tech='encuesta' THEN
   qty:=CASE g WHEN 5 THEN 5 WHEN 6 THEN 6 ELSE 8 END;
   FOR i IN 0..qty-1 LOOP FOREACH k IN ARRAY ARRAY['text','a','b','c'] LOOP IF btrim(coalesce(c->>('q'||i||'_'||k),''))='' THEN RAISE EXCEPTION 'Completa las % preguntas y sus tres opciones',qty; END IF; END LOOP; END LOOP;
  ELSIF tech='entrevista' THEN
   FOREACH k IN ARRAY ARRAY['interview_target','interview0','interview1','interview_media'] LOOP IF btrim(coalesce(c->>k,''))='' THEN RAISE EXCEPTION 'Completa el público, dos preguntas y el enlace de audio o video'; END IF; END LOOP;
  ELSIF tech='observacion' THEN
   FOREACH k IN ARRAY ARRAY['empathy_target','empathy_think','empathy_hear','empathy_see','empathy_do','empathy_basis','empathy_place','empathy_date'] LOOP IF btrim(coalesce(c->>k,''))='' THEN RAISE EXCEPTION 'Completa el mapa, público, lugar, fecha y evidencia'; END IF; END LOOP;
  ELSE RAISE EXCEPTION 'Elige una técnica principal'; END IF;
 END IF;
 FOR item IN SELECT * FROM jsonb_each(p_changes) LOOP
  IF w.content->item.key IS DISTINCT FROM item.value THEN INSERT INTO aula_private.market_contributions(team_id,member_id,recorded_by,field_key) VALUES(tid,p_member,auth.uid(),item.key); END IF;
 END LOOP;
 INSERT INTO public.aula_works(team_id,publication_id,content,status,last_author,updated_at,submitted_at)
 VALUES(tid,p.id,c,CASE WHEN p_submit THEN 'submitted' ELSE 'draft' END,auth.uid(),stamp,CASE WHEN p_submit THEN stamp ELSE NULL END)
 ON CONFLICT(team_id,publication_id) DO UPDATE SET content=excluded.content,status=excluded.status,last_author=excluded.last_author,updated_at=excluded.updated_at,submitted_at=excluded.submitted_at;
 RETURN public.aula_market_v2_snapshot();
END; $$;
CREATE OR REPLACE FUNCTION public.aula_market_v2_add_response(p_member uuid,p_answers jsonb,p_kind text,p_expected timestamptz)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); p public.aula_publications; w public.aula_works; i integer; g integer; k text; val jsonb; instrument jsonb:='[]'::jsonb; qty integer; tech text;
BEGIN
 SELECT grade INTO g FROM public.aula_teams WHERE id=tid AND grade IN(5,6,7);
 IF g IS NULL THEN RAISE EXCEPTION 'Ingresa con tu equipo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.aula_members WHERE id=p_member AND team_id=tid AND active) THEN RAISE EXCEPTION 'Selecciona quién registra'; END IF;
 SELECT pp.* INTO p FROM public.aula_publications pp JOIN public.aula_teams t ON t.grade=pp.grade AND t.parallel=pp.parallel WHERE t.id=tid AND pp.week_number=9;
 IF p.state IS DISTINCT FROM 'available' THEN RAISE EXCEPTION 'La actividad está cerrada'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(tid::text,9));
 SELECT * INTO w FROM public.aula_works WHERE team_id=tid AND publication_id=p.id FOR UPDATE;
 IF w.updated_at IS NULL OR w.updated_at IS DISTINCT FROM p_expected THEN RAISE EXCEPTION 'Guarda y actualiza el instrumento antes de aplicarlo' USING ERRCODE='40001'; END IF;
 tech:=w.content->>'technique';
 IF p_kind IS NULL OR p_kind NOT IN('real','ensayo') OR jsonb_typeof(p_answers) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Revisa las respuestas y el tipo de registro'; END IF;
 IF (SELECT count(*) FROM aula_private.market_responses WHERE team_id=tid)>=100 THEN RAISE EXCEPTION 'Límite de 100 aplicaciones por equipo'; END IF;
 IF tech='encuesta' THEN
  qty:=CASE g WHEN 5 THEN 5 WHEN 6 THEN 6 ELSE 8 END;
  IF jsonb_array_length(p_answers)<>qty THEN RAISE EXCEPTION 'Registra las % respuestas',qty; END IF;
  FOR i IN 0..qty-1 LOOP
   FOREACH k IN ARRAY ARRAY['text','a','b','c'] LOOP IF btrim(coalesce(w.content->>('q'||i||'_'||k),''))='' THEN RAISE EXCEPTION 'Completa y guarda todas las preguntas y opciones'; END IF; END LOOP;
   val:=p_answers->i;
   IF jsonb_typeof(val->'choice') IS DISTINCT FROM 'number' OR (val->>'choice')!~'^[012]$' OR jsonb_typeof(val->'why') IS DISTINCT FROM 'string' OR char_length(val->>'why')>2000 THEN RAISE EXCEPTION 'Respuesta no válida'; END IF;
   instrument:=instrument||jsonb_build_array(jsonb_build_object('text',w.content->>('q'||i||'_text'),'options',jsonb_build_array(w.content->>('q'||i||'_a'),w.content->>('q'||i||'_b'),w.content->>('q'||i||'_c'))));
  END LOOP;
 ELSIF tech='entrevista' AND g=7 THEN
  IF btrim(coalesce(w.content->>'interview_target',''))='' OR btrim(coalesce(w.content->>'interview_media',''))='' THEN RAISE EXCEPTION 'Guarda el público y el enlace de la entrevista'; END IF;
  FOR i IN 0..3 LOOP
   IF btrim(coalesce(w.content->>('interview'||i),''))<>'' THEN
    val:=p_answers->jsonb_array_length(instrument);
    IF jsonb_typeof(val->'text') IS DISTINCT FROM 'string' OR btrim(val->>'text')='' OR char_length(val->>'text')>2000 THEN RAISE EXCEPTION 'Registra la respuesta de cada pregunta abierta'; END IF;
    instrument:=instrument||jsonb_build_array(jsonb_build_object('text',w.content->>('interview'||i),'options','[]'::jsonb,'audience',w.content->>'interview_target','media',w.content->>'interview_media'));
   END IF;
  END LOOP;
  IF jsonb_array_length(instrument)<2 OR jsonb_array_length(p_answers)<>jsonb_array_length(instrument) THEN RAISE EXCEPTION 'Aplica al menos dos preguntas abiertas'; END IF;
 ELSE RAISE EXCEPTION 'Para observación completa y guarda el mapa de empatía'; END IF;
 INSERT INTO aula_private.market_responses(team_id,member_id,kind,technique,instrument,answers) VALUES(tid,p_member,p_kind,tech,instrument,p_answers);
 INSERT INTO aula_private.market_contributions(team_id,member_id,recorded_by,field_key) VALUES(tid,p_member,auth.uid(),'application');
 RETURN public.aula_market_v2_snapshot();
END; $$;
REVOKE ALL ON FUNCTION public.aula_market_v2_snapshot(uuid,integer),public.aula_market_v2_save(uuid,jsonb,timestamptz,boolean),public.aula_market_v2_add_response(uuid,jsonb,text,timestamptz) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_market_v2_snapshot(uuid,integer),public.aula_market_v2_save(uuid,jsonb,timestamptz,boolean),public.aula_market_v2_add_response(uuid,jsonb,text,timestamptz) TO authenticated;
UPDATE public.aula_publications SET instructions='Público objetivo y técnica de investigación. Encuesta de ocho preguntas, entrevista con audio o video, u observación con mapa de empatía. Resultados y análisis editables. Una evaluación 7+3.' WHERE grade=7 AND week_number=9;
COMMIT;
