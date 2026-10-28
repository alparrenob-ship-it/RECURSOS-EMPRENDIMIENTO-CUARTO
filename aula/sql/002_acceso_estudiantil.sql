-- PASO 2 · Acceso estudiantil por lista oficial. Ejecutar después del paso 1.
-- No contiene listas de estudiantes ni secretos. No elimina los equipos existentes.
BEGIN;
CREATE OR REPLACE FUNCTION aula_private.normalizar_nombre(v text)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT regexp_replace(lower(translate(btrim(coalesce(v,'')),
 'ÁÉÍÓÚÜáéíóúü','AEIOUUaeiouu')), '[[:space:]]+', ' ', 'g');
$$;
CREATE OR REPLACE FUNCTION aula_private.coincide_nombre(guardado text, escrito text)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT aula_private.normalizar_nombre(guardado)=aula_private.normalizar_nombre(escrito)
 OR EXISTS (SELECT 1 FROM (SELECT string_to_array(aula_private.normalizar_nombre(guardado),' ') a) s,
 generate_series(1,least(array_length(s.a,1)-1,3)) n
 WHERE array_to_string(s.a[n+1:array_length(s.a,1)]||s.a[1:n],' ')=aula_private.normalizar_nombre(escrito));
$$;
CREATE OR REPLACE FUNCTION aula_private.equipo_estudiante()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT m.team_id FROM public.aula_enrollments e
 JOIN public.aula_members m ON m.id=e.member_id AND m.active
 JOIN auth.users u ON u.id=e.auth_user_id AND u.is_anonymous=true
 WHERE e.auth_user_id=(SELECT auth.uid()) AND e.active;
$$;
REVOKE ALL ON FUNCTION aula_private.normalizar_nombre(text),aula_private.coincide_nombre(text,text),aula_private.equipo_estudiante() FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.aula_student_enter(p_name text,p_grade integer,p_parallel text,p_group integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE uid uuid:=auth.uid(); matching uuid; matched_group integer; matches integer;
BEGIN
 IF uid IS NULL OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=uid AND is_anonymous=true) THEN
 RAISE EXCEPTION 'Sesión estudiantil requerida'; END IF;
 -- Una solicitud fallida revoca el acceso anterior de este navegador.
 UPDATE public.aula_enrollments SET active=false WHERE auth_user_id=uid;
 IF p_grade NOT IN(5,6,7) OR p_parallel NOT IN('A','B','C') OR p_group NOT BETWEEN 1 AND 6
 OR char_length(btrim(p_name)) NOT BETWEEN 4 AND 120 OR position(' ' IN btrim(p_name))=0
 OR p_name IS NULL OR p_grade IS NULL OR p_parallel IS NULL OR p_group IS NULL THEN
 RETURN jsonb_build_object('status','not_member'); END IF;
 IF EXISTS(SELECT 1 FROM public.aula_access_requests WHERE auth_user_id=uid AND requested_at>now()-interval '3 seconds') THEN
 RETURN jsonb_build_object('status','retry'); END IF;
 SELECT count(*) INTO matches FROM public.aula_members m JOIN public.aula_teams t ON t.id=m.team_id
 WHERE m.active AND t.grade=p_grade AND t.parallel=p_parallel AND aula_private.coincide_nombre(m.full_name,p_name);
 IF matches=1 THEN
 SELECT m.id,t.group_number INTO matching,matched_group FROM public.aula_members m JOIN public.aula_teams t ON t.id=m.team_id
 WHERE m.active AND t.grade=p_grade AND t.parallel=p_parallel AND aula_private.coincide_nombre(m.full_name,p_name);
 END IF;
 INSERT INTO public.aula_access_requests(auth_user_id,requested_grade,requested_parallel,requested_group,requested_name,matched_member_id,state,requested_at,reviewed_at)
 VALUES(uid,p_grade,p_parallel,p_group,btrim(p_name),CASE WHEN matched_group=p_group THEN matching END,
 CASE WHEN matching IS NOT NULL AND matched_group=p_group THEN 'approved' ELSE 'denied' END,now(),now())
 ON CONFLICT(auth_user_id) DO UPDATE SET requested_grade=excluded.requested_grade,requested_parallel=excluded.requested_parallel,
 requested_group=excluded.requested_group,requested_name=excluded.requested_name,matched_member_id=excluded.matched_member_id,
 state=excluded.state,requested_at=excluded.requested_at,reviewed_at=excluded.reviewed_at;
 IF matching IS NULL OR matched_group<>p_group THEN RETURN jsonb_build_object('status','not_member'); END IF;
 INSERT INTO public.aula_enrollments(auth_user_id,member_id,active,approved_at) VALUES(uid,matching,true,now())
 ON CONFLICT(auth_user_id) DO UPDATE SET member_id=excluded.member_id,active=true,approved_at=now();
 RETURN jsonb_build_object('status','ok');
END; $$;

CREATE OR REPLACE FUNCTION public.aula_student_snapshot()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); t public.aula_teams; m public.aula_members; p public.aula_publications; result jsonb;
BEGIN
 IF tid IS NULL THEN RETURN jsonb_build_object('status','no_enrollment'); END IF;
 SELECT * INTO t FROM public.aula_teams WHERE id=tid;
 SELECT mm.* INTO m FROM public.aula_members mm JOIN public.aula_enrollments e ON e.member_id=mm.id WHERE e.auth_user_id=auth.uid();
 SELECT * INTO p FROM public.aula_publications WHERE grade=t.grade AND parallel=t.parallel AND week_number=8 AND state IN('available','closed');
 SELECT jsonb_build_object('status','ok','user',jsonb_build_object('grade',t.grade,'parallel',t.parallel,'group',t.group_number,'name',m.full_name),
 'team',jsonb_build_object('name',t.team_name,'color',t.color_hex,'colorName',t.color_name,
 'project',jsonb_build_object('title',t.project_title,'official',t.project_description),
 'members',coalesce((SELECT jsonb_agg(jsonb_build_object('name',full_name,'role',role_name) ORDER BY
 CASE role_name WHEN 'Líder' THEN 1 WHEN 'Secretario' THEN 2 WHEN 'Secretario/a' THEN 2 WHEN 'Investigador' THEN 3 WHEN 'Investigador/a' THEN 3 WHEN 'Diseñador' THEN 4 WHEN 'Diseñador/a' THEN 4 ELSE 5 END,full_name)
 FROM public.aula_members WHERE team_id=tid AND active),'[]'::jsonb)),
 'publication',CASE WHEN p.id IS NULL THEN NULL ELSE jsonb_build_object('id',p.id,'title',p.title,'instructions',p.instructions,'state',p.state) END,
 'work',CASE WHEN p.id IS NULL THEN NULL ELSE (SELECT jsonb_build_object('content',content,'status',status,'savedAt',updated_at,'submittedAt',submitted_at) FROM public.aula_works WHERE team_id=tid AND publication_id=p.id) END,
 'portfolio',(SELECT jsonb_build_object('url',shared_url,'app',app,'updatedAt',updated_at) FROM public.aula_portfolios WHERE team_id=tid)) INTO result;
 RETURN result;
END; $$;

CREATE OR REPLACE FUNCTION public.aula_student_save_work(p_content jsonb,p_submit boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante(); p public.aula_publications; g integer; n integer; r text; cleaned jsonb;
BEGIN
 IF tid IS NULL THEN RAISE EXCEPTION 'Tu registro ya no pertenece a un equipo activo'; END IF;
 SELECT grade INTO g FROM public.aula_teams WHERE id=tid;
 SELECT pp.* INTO p FROM public.aula_publications pp JOIN public.aula_teams t ON t.grade=pp.grade AND t.parallel=pp.parallel
 WHERE t.id=tid AND pp.week_number=8 FOR SHARE OF pp;
 IF p.id IS NULL OR p.state<>'available' THEN RAISE EXCEPTION 'La docente no ha habilitado esta actividad'; END IF;
 IF p_content IS NULL OR jsonb_typeof(p_content)<>'object' OR jsonb_typeof(p_content->'ods') IS DISTINCT FROM 'array'
 OR jsonb_typeof(p_content->'reasons') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Revisa los cuatro recuadros'; END IF;
 IF jsonb_array_length(p_content->'ods')<>4 OR jsonb_array_length(p_content->'reasons')<>4
 OR coalesce(p_content->>'principal','') !~ '^[0-3]$' THEN RAISE EXCEPTION 'Revisa los cuatro recuadros'; END IF;
 FOR n IN 0..3 LOOP
 IF p_content->'ods'->n<>'null'::jsonb AND (jsonb_typeof(p_content->'ods'->n)<>'number' OR (p_content->'ods'->>n)!~ '^([1-9]|1[0-7])$') THEN RAISE EXCEPTION 'ODS no válido'; END IF;
 IF jsonb_typeof(p_content->'reasons'->n)<>'string' OR char_length(p_content->'reasons'->>n)>250 THEN RAISE EXCEPTION 'Explicación demasiado larga'; END IF;
 IF p_submit AND (p_content->'ods'->n='null'::jsonb OR char_length(btrim(p_content->'reasons'->>n))<8) THEN RAISE EXCEPTION 'Completa los cuatro ODS y explica su relación'; END IF;
 END LOOP;
 IF (SELECT count(*)<>count(DISTINCT value) FROM jsonb_array_elements(p_content->'ods') WHERE value<>'null'::jsonb) THEN RAISE EXCEPTION 'Elige cuatro ODS distintos'; END IF;
 IF char_length(coalesce(p_content->>'indicator',''))>150 OR (p_submit AND g=7 AND char_length(btrim(coalesce(p_content->>'indicator','')))<5) THEN RAISE EXCEPTION 'Revisa el indicador'; END IF;
 cleaned=jsonb_build_object('ods',p_content->'ods','reasons',p_content->'reasons','principal',(p_content->>'principal')::integer,'indicator',coalesce(p_content->>'indicator',''));
 INSERT INTO public.aula_works(team_id,publication_id,content,status,last_author,updated_at,submitted_at)
 VALUES(tid,p.id,cleaned,CASE WHEN p_submit THEN 'submitted' ELSE 'draft' END,auth.uid(),now(),CASE WHEN p_submit THEN now() END)
 ON CONFLICT(team_id,publication_id) DO UPDATE SET content=excluded.content,status=excluded.status,last_author=excluded.last_author,updated_at=excluded.updated_at,submitted_at=excluded.submitted_at;
 RETURN public.aula_student_snapshot();
END; $$;

CREATE OR REPLACE FUNCTION public.aula_student_save_portfolio(p_url text,p_app text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tid uuid:=aula_private.equipo_estudiante();
BEGIN
 IF tid IS NULL THEN RAISE EXCEPTION 'Tu registro ya no pertenece a un equipo activo'; END IF;
 -- Las restricciones de la tabla validan HTTPS, iCloud, Pages y Keynote.
 INSERT INTO public.aula_portfolios(team_id,app,shared_url,updated_by,updated_at) VALUES(tid,p_app,btrim(p_url),auth.uid(),now())
 ON CONFLICT(team_id) DO UPDATE SET app=excluded.app,shared_url=excluded.shared_url,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 RETURN public.aula_student_snapshot();
END; $$;
CREATE OR REPLACE FUNCTION public.aula_student_leave()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 UPDATE public.aula_enrollments SET active=false WHERE auth_user_id=auth.uid();
$$;
REVOKE ALL ON FUNCTION public.aula_student_enter(text,integer,text,integer),public.aula_student_snapshot(),public.aula_student_save_work(jsonb,boolean),public.aula_student_save_portfolio(text,text),public.aula_student_leave() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_student_enter(text,integer,text,integer),public.aula_student_snapshot(),public.aula_student_save_work(jsonb,boolean),public.aula_student_save_portfolio(text,text),public.aula_student_leave() TO authenticated;
-- No se crean políticas de lectura pública: las tablas siguen protegidas por RLS.
CREATE OR REPLACE FUNCTION public.aula_setup_status()
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$
 SELECT jsonb_build_object('schema_version',2,'status','student_ready');
$$;
COMMIT;
SELECT 'Acceso estudiantil preparado. Ahora activa Allow anonymous sign-ins en Authentication.' AS resultado;
