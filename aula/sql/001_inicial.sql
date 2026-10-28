-- AULA EMPRENDIMIENTO · PASO 1: tablas privadas y cuenta docente autorizada.
-- Ejecutar en el SQL Editor del proyecto Supabase, con el rol postgres.
-- No contiene contraseñas ni claves privadas. No incorpora nombres de alumnos.
-- Esta etapa NO abre todavía el acceso de estudiantes.
-- Es repetible: no elimina ni reemplaza registros existentes.
BEGIN;

CREATE SCHEMA IF NOT EXISTS aula_private;
REVOKE ALL ON SCHEMA aula_private FROM PUBLIC, anon, authenticated;
CREATE TABLE IF NOT EXISTS aula_private.teacher_allowlist (
  email text PRIMARY KEY CHECK (email = lower(email)),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE aula_private.teacher_allowlist ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE aula_private.teacher_allowlist FROM PUBLIC, anon, authenticated;
INSERT INTO aula_private.teacher_allowlist(email)
VALUES ('alparrenob@eightacademy.edu.ec') ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE FUNCTION public.aula_is_teacher()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users AS u
    JOIN aula_private.teacher_allowlist AS t ON t.email = lower(u.email)
    WHERE u.id = (SELECT auth.uid())
      AND u.email_confirmed_at IS NOT NULL
      AND coalesce(u.is_anonymous, false) = false
  );
$$;
REVOKE ALL ON FUNCTION public.aula_is_teacher() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.aula_is_teacher() TO authenticated;

CREATE TABLE IF NOT EXISTS public.aula_teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grade smallint NOT NULL CHECK (grade IN (5,6,7)),
  parallel text NOT NULL CHECK (parallel IN ('A','B','C')),
  group_number smallint NOT NULL CHECK (group_number BETWEEN 1 AND 6),
  color_name text NOT NULL CHECK (char_length(color_name) BETWEEN 1 AND 40),
  color_hex text NOT NULL CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  team_name text NOT NULL DEFAULT '',
  project_title text NOT NULL CHECK (char_length(project_title) BETWEEN 1 AND 500),
  project_description text NOT NULL DEFAULT '',
  agreement text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grade, parallel, group_number)
);

CREATE TABLE IF NOT EXISTS public.aula_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id uuid NOT NULL REFERENCES public.aula_teams(id),
  full_name text NOT NULL CHECK (char_length(btrim(full_name)) BETWEEN 3 AND 120),
  role_name text NOT NULL DEFAULT '' CHECK (char_length(role_name) <= 100),
  active boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS aula_members_identity
  ON public.aula_members(team_id, lower(btrim(full_name)));

CREATE TABLE IF NOT EXISTS public.aula_publications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grade smallint NOT NULL CHECK (grade IN (5,6,7)),
  parallel text NOT NULL CHECK (parallel IN ('A','B','C')),
  week_number smallint NOT NULL CHECK (week_number BETWEEN 1 AND 60),
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 300),
  instructions text NOT NULL DEFAULT '',
  state text NOT NULL DEFAULT 'draft' CHECK (state IN ('draft','available','closed')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (grade, parallel, week_number)
);

CREATE TABLE IF NOT EXISTS public.aula_access_requests (
  auth_user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  requested_grade smallint NOT NULL CHECK (requested_grade IN (5,6,7)),
  requested_parallel text NOT NULL CHECK (requested_parallel IN ('A','B','C')),
  requested_group smallint NOT NULL CHECK (requested_group BETWEEN 1 AND 6),
  requested_name text NOT NULL CHECK (char_length(btrim(requested_name)) BETWEEN 3 AND 120),
  matched_member_id uuid REFERENCES public.aula_members(id),
  state text NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','approved','denied')),
  requested_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.aula_enrollments (
  auth_user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  member_id uuid NOT NULL REFERENCES public.aula_members(id),
  active boolean NOT NULL DEFAULT true,
  approved_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.aula_works (
  team_id uuid NOT NULL REFERENCES public.aula_teams(id),
  publication_id uuid NOT NULL REFERENCES public.aula_publications(id),
  content jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(content) = 'object'),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','submitted')),
  last_author uuid REFERENCES auth.users(id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  submitted_at timestamptz,
  PRIMARY KEY (team_id, publication_id)
);

CREATE TABLE IF NOT EXISTS public.aula_portfolios (
  team_id uuid PRIMARY KEY REFERENCES public.aula_teams(id),
  app text NOT NULL CHECK (app IN ('Pages','Keynote')),
  shared_url text NOT NULL CHECK (
    char_length(shared_url) <= 3000 AND (
      shared_url ~ '^https://(www[.])?icloud[.]com/(pages|keynote)/[^[:space:]]+$'
      OR shared_url ~ '^https://share[.]icloud[.]com/[^[:space:]]+$'
    )
  ),
  updated_by uuid REFERENCES auth.users(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.aula_group_grades (
  team_id uuid NOT NULL REFERENCES public.aula_teams(id),
  publication_id uuid NOT NULL REFERENCES public.aula_publications(id),
  ods_score smallint CHECK (ods_score BETWEEN 0 AND 4),
  reasons_score smallint CHECK (reasons_score BETWEEN 0 AND 4),
  feedback text NOT NULL DEFAULT '' CHECK (char_length(feedback) <= 3000),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (team_id, publication_id)
);

CREATE TABLE IF NOT EXISTS public.aula_individual_grades (
  member_id uuid NOT NULL REFERENCES public.aula_members(id),
  publication_id uuid NOT NULL REFERENCES public.aula_publications(id),
  contribution_score smallint CHECK (contribution_score BETWEEN 0 AND 2),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (member_id, publication_id)
);

-- Acceso cerrado por defecto. Solo el docente con correo confirmado puede
-- consultar, insertar o actualizar. El acceso estudiantil se añade en el paso 2.
DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'aula_teams','aula_members','aula_publications','aula_access_requests',
    'aula_enrollments','aula_works','aula_portfolios',
    'aula_group_grades','aula_individual_grades'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, anon, authenticated', table_name);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE ON TABLE public.%I TO authenticated', table_name);
    IF NOT EXISTS (
      SELECT 1 FROM pg_catalog.pg_policies
      WHERE schemaname = 'public' AND tablename = table_name AND policyname = 'aula_teacher_only'
    ) THEN
      EXECUTE format(
        'CREATE POLICY aula_teacher_only ON public.%I FOR ALL TO authenticated USING ((SELECT public.aula_is_teacher())) WITH CHECK ((SELECT public.aula_is_teacher()))',
        table_name
      );
    END IF;
  END LOOP;
END;
$$;

-- Una actividad por semana, grado y paralelo. Borrador hasta configurar Auth.
INSERT INTO public.aula_publications(grade, parallel, week_number, title, instructions, state)
SELECT g, p, 8, 'ODS vinculados al proyecto',
  CASE g
    WHEN 5 THEN 'Elegir cuatro ODS distintos y explicar su relación con el proyecto del equipo. Crear una página en Pages con cuatro logos en una fila y una explicación breve debajo de cada uno.'
    WHEN 6 THEN 'Elegir cuatro ODS distintos y explicar qué acción del proyecto aporta a cada ODS y a quién beneficia. Crear una página en Pages con cuatro logos en una fila y explicaciones breves.'
    WHEN 7 THEN 'Elegir cuatro ODS distintos, justificar su vinculación con el proyecto y proponer un indicador observable del ODS principal. Crear una página en Pages con cuatro logos en una fila y explicaciones breves.'
  END, 'draft'
FROM unnest(ARRAY[5,6,7]::smallint[]) AS grades(g)
CROSS JOIN unnest(ARRAY['A','B','C']::text[]) AS parallels(p)
ON CONFLICT (grade, parallel, week_number) DO NOTHING;

-- Comprobación pública: devuelve solo estado técnico, nunca datos de alumnos.
CREATE OR REPLACE FUNCTION public.aula_setup_status()
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT jsonb_build_object('schema_version', 1, 'status', 'awaiting_auth_setup');
$$;
REVOKE ALL ON FUNCTION public.aula_setup_status() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.aula_setup_status() TO anon, authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated;

COMMIT;
SELECT 'Tablas creadas con protección. Siguiente paso: configurar el acceso docente.' AS resultado;
