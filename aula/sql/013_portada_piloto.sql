-- Portada independiente de las actividades; piloto sexto C, grupo 1.
create table if not exists aula_private.portfolio_covers (
 team_id uuid primary key references public.aula_teams(id) on delete cascade,
 design jsonb not null default '{}'::jsonb,
 version bigint not null default 1,
 updated_at timestamptz not null default now()
);
alter table aula_private.portfolio_covers enable row level security;
revoke all on aula_private.portfolio_covers from public,anon,authenticated;
create or replace function public.aula_portfolio_cover(p_design jsonb default null,p_expected bigint default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare tid uuid:=aula_private.equipo_estudiante(); r aula_private.portfolio_covers; k text; v jsonb; n numeric;
begin
 if tid is null or not exists(select 1 from public.aula_teams where id=tid and grade=6 and parallel='C' and group_number=1) then raise exception 'Portada disponible solo en el aula piloto'; end if;
 if p_design is not null then
  if jsonb_typeof(p_design)<>'object' or octet_length(p_design::text)>350000 then raise exception 'Revisa el tamaño de la portada'; end if;
  for k,v in select * from jsonb_each(p_design) loop
   if k in ('name','slogan','topic') then
    if jsonb_typeof(v)<>'string' or length(v#>>'{}')>(case when k='topic' then 400 when k='slogan' then 180 else 80 end) then raise exception 'Texto demasiado largo'; end if;
   elsif k in ('background','primary','accent','text') then
    if (v#>>'{}') !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Color no válido'; end if;
   elsif k='logo' then
    if jsonb_typeof(v)<>'string' or length(v#>>'{}')>320000 or ((v#>>'{}')<>'' and (v#>>'{}') !~ '^data:image/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$') then raise exception 'Imagen no válida'; end if;
   elsif k in ('size','zoom','x','y') then
    if jsonb_typeof(v)<>'number' then raise exception 'Ajuste no válido'; end if;
    n:=(v#>>'{}')::numeric;
    if (k='size' and n not between 14 and 35) or (k='zoom' and n not between 100 and 250) or (k in ('x','y') and n not between 0 and 100) then raise exception 'Ajuste fuera de rango'; end if;
   elsif k='style' then
    if (v#>>'{}') not in ('tech','gradient','plain') then raise exception 'Estilo no válido'; end if;
   elsif k='shape' then
    if (v#>>'{}') not in ('original','square','circle') then raise exception 'Recorte no válido'; end if;
   else raise exception 'Campo de portada no válido'; end if;
  end loop;
  if not (p_design ?& array['name','slogan','topic','background','primary','accent','text','logo','size','zoom','x','y','style','shape']) then raise exception 'Portada incompleta'; end if;
  perform pg_advisory_xact_lock(hashtextextended(tid::text,13));
  select * into r from aula_private.portfolio_covers where team_id=tid for update;
  if (r.team_id is null and p_expected is not null) or (r.team_id is not null and p_expected is distinct from r.version) then raise exception 'La portada cambió. Actualiza antes de volver a guardar'; end if;
  insert into aula_private.portfolio_covers(team_id,design) values(tid,p_design)
  on conflict(team_id) do update set design=excluded.design,version=portfolio_covers.version+1,updated_at=now();
 end if;
 select * into r from aula_private.portfolio_covers where team_id=tid;
 return jsonb_build_object('design',coalesce(r.design,'{}'::jsonb),'version',r.version);
end; $$;
revoke all on function public.aula_portfolio_cover(jsonb,bigint) from public,anon;
grant execute on function public.aula_portfolio_cover(jsonb,bigint) to authenticated;
