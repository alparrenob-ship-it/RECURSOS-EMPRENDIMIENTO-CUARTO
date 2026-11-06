-- Rueda de ideas, independiente de actividades; piloto sexto C, grupo 1.
create table if not exists aula_private.portfolio_ideas (
 team_id uuid primary key references public.aula_teams(id) on delete cascade,
 design jsonb not null default '{}'::jsonb,
 version bigint not null default 1,
 updated_at timestamptz not null default now()
);
alter table aula_private.portfolio_ideas enable row level security;
revoke all on aula_private.portfolio_ideas from public,anon,authenticated;
create or replace function public.aula_portfolio_ideas(p_design jsonb default null,p_expected bigint default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare tid uuid:=aula_private.equipo_estudiante(); r aula_private.portfolio_ideas; k text; v jsonb; n numeric;
begin
 if tid is null or not exists(select 1 from public.aula_teams where id=tid and grade=6 and parallel='C' and group_number=1) then raise exception 'Diapositiva disponible solo en el aula piloto'; end if;
 if p_design is not null then
  if jsonb_typeof(p_design)<>'object' or octet_length(p_design::text)>20000 then raise exception 'Revisa el tamaño de la diapositiva'; end if;
  if not (p_design ? 'ideas') or jsonb_typeof(p_design->'ideas')<>'array' or jsonb_array_length(p_design->'ideas')>12 or p_design - 'ideas' <> '{}'::jsonb then raise exception 'Revisa las ideas del equipo'; end if;
  for v in select value from jsonb_array_elements(p_design->'ideas') loop
   if jsonb_typeof(v)<>'object' or not (v ?& array['name','idea','explanation']) or v - array['name','idea','explanation'] <> '{}'::jsonb then raise exception 'Idea incompleta'; end if;
   for k in select unnest(array['name','idea','explanation']) loop
    if jsonb_typeof(v->k)<>'string' or length(v->>k)>(case k when 'name' then 80 when 'idea' then 100 else 180 end) then raise exception 'Resume el texto de la idea'; end if;
   end loop;
  end loop;
  perform pg_advisory_xact_lock(hashtextextended(tid::text,17));
  select * into r from aula_private.portfolio_ideas where team_id=tid for update;
  if (r.team_id is null and p_expected is not null) or (r.team_id is not null and p_expected is distinct from r.version) then raise exception 'La diapositiva cambió. Actualiza antes de volver a guardar'; end if;
  insert into aula_private.portfolio_ideas(team_id,design) values(tid,p_design)
  on conflict(team_id) do update set design=excluded.design,version=portfolio_ideas.version+1,updated_at=now();
 end if;
 select * into r from aula_private.portfolio_ideas where team_id=tid;
 return jsonb_build_object('design',coalesce(r.design,'{}'::jsonb),'version',r.version);
end; $$;
revoke all on function public.aula_portfolio_ideas(jsonb,bigint) from public,anon;
grant execute on function public.aula_portfolio_ideas(jsonb,bigint) to authenticated;
