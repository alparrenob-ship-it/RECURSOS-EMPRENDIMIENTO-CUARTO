-- PASO 3 · Nombres y apellidos flexibles y saludo por nombre.
-- Ejecutar después del paso 2. Conserva equipos, trabajos y calificaciones.
BEGIN;
-- Las listas oficiales usan apellido(s) antes de nombre(s).
CREATE OR REPLACE FUNCTION aula_private.partes_nombre(v text)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE a text[]:=regexp_split_to_array(btrim(regexp_replace(coalesce(v,''),'[[:space:]]+',' ','g')),' '); n integer; corte integer;
BEGIN
 n:=coalesce(array_length(a,1),0);
 IF n<2 THEN RETURN jsonb_build_object('apellidos','','nombres',coalesce(v,'')); END IF;
 -- Coma explícita: apellidos, nombres.
 IF position(',' IN v)>0 THEN RETURN jsonb_build_object('apellidos',btrim(split_part(v,',',1)),'nombres',btrim(substring(v FROM position(',' IN v)+1))); END IF;
 corte:=CASE WHEN n>=4 THEN 2 ELSE 1 END;
 IF lower(a[1]) IN('de','del','la','las','los','san','santa','van','von') THEN
 corte:=1;
 WHILE corte<n-1 AND lower(a[corte]) IN('de','del','la','las','los','san','santa','van','von') LOOP corte:=corte+1; END LOOP;
 END IF;
 RETURN jsonb_build_object('apellidos',array_to_string(a[1:corte],' '),'nombres',array_to_string(a[corte+1:n],' '));
END; $$;
CREATE OR REPLACE FUNCTION aula_private.coincide_nombre(guardado text, escrito text)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 WITH partes AS (SELECT aula_private.partes_nombre(guardado) p),
 entrada AS (SELECT DISTINCT token FROM unnest(string_to_array(aula_private.normalizar_nombre(escrito),' ')) token
 WHERE token NOT IN('','de','del','la','las','los','san','santa','van','von'))
 SELECT EXISTS(SELECT 1 FROM entrada WHERE token=ANY(string_to_array(aula_private.normalizar_nombre(p->>'nombres'),' ')))
 AND EXISTS(SELECT 1 FROM entrada WHERE token=ANY(string_to_array(aula_private.normalizar_nombre(p->>'apellidos'),' ')))
 AND (SELECT count(*) FROM entrada)>=2 FROM partes;
$$;
REVOKE ALL ON FUNCTION aula_private.partes_nombre(text) FROM PUBLIC,anon,authenticated;
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
 WHERE m.active AND t.grade=p_grade AND t.parallel=p_parallel AND t.group_number=p_group AND aula_private.coincide_nombre(m.full_name,p_name);
 IF matches=1 THEN
 SELECT m.id,t.group_number INTO matching,matched_group FROM public.aula_members m JOIN public.aula_teams t ON t.id=m.team_id
 WHERE m.active AND t.grade=p_grade AND t.parallel=p_parallel AND t.group_number=p_group AND aula_private.coincide_nombre(m.full_name,p_name);
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
 SELECT jsonb_build_object('status','ok','user',jsonb_build_object('grade',t.grade,'parallel',t.parallel,'group',t.group_number,'name',m.full_name,'givenName',aula_private.partes_nombre(m.full_name)->>'nombres'),
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

REVOKE ALL ON FUNCTION public.aula_student_enter(text,integer,text,integer),public.aula_student_snapshot() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_student_enter(text,integer,text,integer),public.aula_student_snapshot() TO authenticated;
COMMIT;
SELECT 'Nombres actualizados: un nombre y un apellido del grupo correcto. Saludo por nombre.' AS resultado;
