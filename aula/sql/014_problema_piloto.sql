-- Hoja 2: Problema, independiente de actividades; piloto sexto C, grupo 1.
create table if not exists aula_private.portfolio_problems (
 team_id uuid primary key references public.aula_teams(id) on delete cascade,
 design jsonb not null default '{}'::jsonb,
 version bigint not null default 1,
 updated_at timestamptz not null default now()
);
alter table aula_private.portfolio_problems enable row level security;
revoke all on aula_private.portfolio_problems from public,anon,authenticated;
create or replace function public.aula_portfolio_problem(p_design jsonb default null,p_expected bigint default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare tid uuid:=aula_private.equipo_estudiante(); r aula_private.portfolio_problems; k text; v jsonb; n numeric;
begin
 if tid is null or not exists(select 1 from public.aula_teams where id=tid and grade=6 and parallel='C' and group_number=1) then raise exception 'Diapositiva disponible solo en el aula piloto'; end if;
 if p_design is not null then
  if jsonb_typeof(p_design)<>'object' or octet_length(p_design::text)>960000 then raise exception 'Revisa el tamaño de la diapositiva'; end if;
  for k,v in select * from jsonb_each(p_design) loop
   if k in ('text0','text1','text2') then
    if jsonb_typeof(v)<>'string' or length(v#>>'{}')>500 then raise exception 'El texto admite hasta 500 caracteres'; end if;
   elsif k in ('image0','image1','image2') then
    if jsonb_typeof(v)<>'string' or length(v#>>'{}')>320000 or ((v#>>'{}')<>'' and (v#>>'{}') !~ '^data:image/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$') then raise exception 'Imagen no válida'; end if;
   else raise exception 'Campo no válido'; end if;
  end loop;
  if not (p_design ?& array['text0','text1','text2','image0','image1','image2']) then raise exception 'Diapositiva incompleta'; end if;
  perform pg_advisory_xact_lock(hashtextextended(tid::text,14));
  select * into r from aula_private.portfolio_problems where team_id=tid for update;
  if (r.team_id is null and p_expected is not null) or (r.team_id is not null and p_expected is distinct from r.version) then raise exception 'La diapositiva cambió. Actualiza antes de volver a guardar'; end if;
  insert into aula_private.portfolio_problems(team_id,design) values(tid,p_design)
  on conflict(team_id) do update set design=excluded.design,version=portfolio_problems.version+1,updated_at=now();
 end if;
 select * into r from aula_private.portfolio_problems where team_id=tid;
 return jsonb_build_object('design',coalesce(r.design,'{}'::jsonb),'version',r.version);
end; $$;
revoke all on function public.aula_portfolio_problem(jsonb,bigint) from public,anon;
grant execute on function public.aula_portfolio_problem(jsonb,bigint) to authenticated;
