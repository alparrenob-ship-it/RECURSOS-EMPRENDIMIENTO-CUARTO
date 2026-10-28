-- PASO 5 · Mostrar al estudiante el proyecto editado por su docente.
-- Solo actualiza la consulta de su propio equipo. No cambia datos ni permisos de edición.
BEGIN;
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
 'project',jsonb_build_object('title',t.project_title,'official',t.project_description,'problem',coalesce(to_jsonb(t)->>'project_problem',''),'solution',coalesce(to_jsonb(t)->>'project_solution','')),
 'members',coalesce((SELECT jsonb_agg(jsonb_build_object('name',full_name,'role',role_name) ORDER BY
 CASE role_name WHEN 'Líder' THEN 1 WHEN 'Secretario' THEN 2 WHEN 'Secretario/a' THEN 2 WHEN 'Investigador' THEN 3 WHEN 'Investigador/a' THEN 3 WHEN 'Diseñador' THEN 4 WHEN 'Diseñador/a' THEN 4 ELSE 5 END,full_name)
 FROM public.aula_members WHERE team_id=tid AND active),'[]'::jsonb)),
 'publication',CASE WHEN p.id IS NULL THEN NULL ELSE jsonb_build_object('id',p.id,'title',p.title,'instructions',p.instructions,'state',p.state) END,
 'work',CASE WHEN p.id IS NULL THEN NULL ELSE (SELECT jsonb_build_object('content',content,'status',status,'savedAt',updated_at,'submittedAt',submitted_at) FROM public.aula_works WHERE team_id=tid AND publication_id=p.id) END,
 'portfolio',(SELECT jsonb_build_object('url',shared_url,'app',app,'updatedAt',updated_at) FROM public.aula_portfolios WHERE team_id=tid)) INTO result;
 RETURN result;
END; $$;

REVOKE ALL ON FUNCTION public.aula_student_snapshot() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_student_snapshot() TO authenticated;
COMMIT;
SELECT 'Nuestro proyecto conectado: tema, nombre del equipo, problema y solución de la docente.' AS resultado;
