-- PASO 4 · Panel por actividad/equipo y evaluación 7 + 3.
-- Conserva las notas históricas 4 + 4 + 2 sin convertirlas ni borrarlas.
BEGIN;
ALTER TABLE public.aula_teams ADD COLUMN IF NOT EXISTS project_problem text NOT NULL DEFAULT '';
ALTER TABLE public.aula_teams ADD COLUMN IF NOT EXISTS project_solution text NOT NULL DEFAULT '';
CREATE TABLE IF NOT EXISTS public.aula_evaluations (
 team_id uuid NOT NULL REFERENCES public.aula_teams(id),
 publication_id uuid NOT NULL REFERENCES public.aula_publications(id),
 rubric_version text NOT NULL DEFAULT 'group7-individual3-v1' CHECK(rubric_version='group7-individual3-v1'),
 ods_score smallint CHECK(ods_score BETWEEN 0 AND 3),
 reasons_score smallint CHECK(reasons_score BETWEEN 0 AND 2),
 teamwork_score smallint CHECK(teamwork_score BETWEEN 0 AND 2),
 individual_scores jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(individual_scores)='object'),
 feedback text NOT NULL DEFAULT '' CHECK(char_length(feedback)<=3000),
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(team_id,publication_id)
);
ALTER TABLE public.aula_evaluations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.aula_evaluations FROM PUBLIC,anon,authenticated;
GRANT SELECT ON TABLE public.aula_evaluations TO authenticated;
DROP POLICY IF EXISTS aula_teacher_only ON public.aula_evaluations;
CREATE POLICY aula_teacher_only ON public.aula_evaluations FOR SELECT TO authenticated USING((SELECT public.aula_is_teacher()));
CREATE OR REPLACE FUNCTION public.aula_teacher_save_evaluation(p_team uuid,p_publication uuid,p_values jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE k text; v jsonb; item record; clean jsonb:='{}'::jsonb; row_result public.aula_evaluations;
BEGIN
 IF NOT public.aula_is_teacher() THEN RAISE EXCEPTION 'Acceso exclusivo docente'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.aula_teams t JOIN public.aula_publications p ON p.grade=t.grade AND p.parallel=t.parallel WHERE t.id=p_team AND p.id=p_publication) THEN RAISE EXCEPTION 'Equipo y actividad no corresponden al mismo paralelo'; END IF;
 IF p_values IS NULL OR jsonb_typeof(p_values)<>'object' OR jsonb_typeof(p_values->'members') IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Revisa la rúbrica'; END IF;
 FOREACH k IN ARRAY ARRAY['ods','reasons','teamwork'] LOOP
 v:=p_values->k;
 IF v IS NULL OR (v<>'null'::jsonb AND (jsonb_typeof(v)<>'number' OR (v#>>'{}')!~CASE WHEN k='ods' THEN '^[0-3]$' ELSE '^[0-2]$' END)) THEN RAISE EXCEPTION 'Revisa los 7 puntos grupales'; END IF;
 END LOOP;
 FOR item IN SELECT * FROM jsonb_each(p_values->'members') LOOP
 IF NOT EXISTS(SELECT 1 FROM public.aula_members WHERE id::text=item.key AND team_id=p_team AND active) THEN RAISE EXCEPTION 'Un integrante cambió de equipo. Actualiza antes de evaluar'; END IF;
 IF jsonb_typeof(item.value)<>'object' THEN RAISE EXCEPTION 'Revisa el aporte individual'; END IF;
 FOREACH k IN ARRAY ARRAY['order','organization','contribution'] LOOP
 v:=item.value->k;
 IF v IS NULL OR (v<>'null'::jsonb AND (jsonb_typeof(v)<>'number' OR (v#>>'{}')!~'^[01]$')) THEN RAISE EXCEPTION 'Cada criterio individual vale 1 punto'; END IF;
 END LOOP;
 clean:=clean||jsonb_build_object(item.key,jsonb_build_object('order',item.value->'order','organization',item.value->'organization','contribution',item.value->'contribution'));
 END LOOP;
 -- Un guardado no puede omitir integrantes activos y convertirlos en ceros.
 IF (SELECT count(*) FROM public.aula_members WHERE team_id=p_team AND active)<>(SELECT count(*) FROM jsonb_object_keys(clean)) THEN RAISE EXCEPTION 'La lista de integrantes cambió. Actualiza y vuelve a evaluar'; END IF;
 IF char_length(coalesce(p_values->>'comment',''))>3000 THEN RAISE EXCEPTION 'Retroalimentación demasiado larga'; END IF;
 -- Conserva valoraciones de integrantes retirados para mantener el historial.
 clean:=coalesce((SELECT individual_scores FROM public.aula_evaluations WHERE team_id=p_team AND publication_id=p_publication),'{}'::jsonb)||clean;
 INSERT INTO public.aula_evaluations(team_id,publication_id,ods_score,reasons_score,teamwork_score,individual_scores,feedback,updated_at)
 VALUES(p_team,p_publication,(p_values->>'ods')::smallint,(p_values->>'reasons')::smallint,(p_values->>'teamwork')::smallint,clean,coalesce(p_values->>'comment',''),now())
 ON CONFLICT(team_id,publication_id) DO UPDATE SET ods_score=excluded.ods_score,reasons_score=excluded.reasons_score,teamwork_score=excluded.teamwork_score,individual_scores=excluded.individual_scores,feedback=excluded.feedback,updated_at=excluded.updated_at
 RETURNING * INTO row_result;
 RETURN to_jsonb(row_result);
END; $$;
REVOKE ALL ON FUNCTION public.aula_teacher_save_evaluation(uuid,uuid,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.aula_teacher_save_evaluation(uuid,uuid,jsonb) TO authenticated;
COMMIT;
SELECT 'Panel preparado: proyecto editable y evaluación de 7 puntos grupales + 3 individuales. Notas anteriores conservadas.' AS resultado;
