-- Cuarto comparte identidad de equipos; escritura exclusiva de la docente.
alter table public.aula_teams drop constraint aula_teams_grade_check;
alter table public.aula_teams add constraint aula_teams_grade_check check(grade in(4,5,6,7));
create table aula_private.fourth_portfolios(team_id uuid primary key references public.aula_teams(id), data jsonb not null default '{}'::jsonb, version bigint not null default 1, updated_at timestamptz not null default now());
alter table aula_private.fourth_portfolios enable row level security;
revoke all on aula_private.fourth_portfolios from public,anon,authenticated;
create function public.aula_fourth_workspace(p_team uuid default null,p_data jsonb default null,p_expected bigint default null,p_members jsonb default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r aula_private.fourth_portfolios; m jsonb; t public.aula_teams; total integer;
begin
 if auth.uid() is null or not public.aula_is_teacher() then raise exception 'Acceso docente requerido'; end if;
 if p_data is not null or p_members is not null then
  select * into t from public.aula_teams where id=p_team and grade=4 for update;
  if not found then raise exception 'Equipo de cuarto no válido'; end if;
  select * into r from aula_private.fourth_portfolios where team_id=p_team for update;
  if r.version is distinct from p_expected then raise exception 'El equipo cambió. Actualiza antes de guardar'; end if;
  if p_data is not null then
   if jsonb_typeof(p_data)<>'object' or octet_length(p_data::text)>6000000 then raise exception 'Reduce el tamaño de las imágenes del portafolio'; end if;
   if length(coalesce(p_data->>'topic','')) not between 1 and 500 or length(coalesce(p_data->>'teamName',''))>120 or length(coalesce(p_data->>'problemText',''))>2000 or length(coalesce(p_data->>'solutionText',''))>4000 then raise exception 'Revisa los textos del proyecto'; end if;
   update aula_private.fourth_portfolios set data=p_data,version=version+1,updated_at=now() where team_id=p_team;
   update public.aula_teams set team_name=p_data->>'teamName',project_title=p_data->>'topic',project_problem=p_data->>'problemText',project_solution=p_data->>'solutionText',updated_at=now() where id=p_team;
  end if;
  if p_members is not null then
   if jsonb_typeof(p_members)<>'array' or jsonb_array_length(p_members)>12 then raise exception 'Revisa los integrantes'; end if;
   select count(distinct lower(btrim(value->>'name'))) into total from jsonb_array_elements(p_members);
   if total<>jsonb_array_length(p_members) then raise exception 'Hay integrantes repetidos'; end if;
   for m in select value from jsonb_array_elements(p_members) loop
    if length(btrim(coalesce(m->>'name',''))) not between 3 and 120 or length(coalesce(m->>'role',''))>100 then raise exception 'Revisa nombres y roles'; end if;
   end loop;
   update public.aula_members set active=false,updated_at=now() where team_id=p_team and lower(btrim(full_name)) not in(select lower(btrim(value->>'name')) from jsonb_array_elements(p_members));
   for m in select value from jsonb_array_elements(p_members) loop
    insert into public.aula_members(team_id,full_name,role_name) values(p_team,btrim(m->>'name'),coalesce(m->>'role','')) on conflict(team_id,lower(btrim(full_name))) do update set role_name=excluded.role_name,active=true,updated_at=now();
   end loop;
   if p_data is null then update aula_private.fourth_portfolios set version=version+1,updated_at=now() where team_id=p_team; end if;
  end if;
 end if;
 return jsonb_build_object('teams',coalesce((select jsonb_agg(jsonb_build_object('id',tt.id,'parallel',tt.parallel,'group',tt.group_number,'color',tt.color_hex,'colorName',tt.color_name,'data',pp.data,'version',pp.version,'updatedAt',pp.updated_at,'members',coalesce((select jsonb_agg(jsonb_build_object('id',mm.id,'name',mm.full_name,'role',mm.role_name) order by mm.full_name) from public.aula_members mm where mm.team_id=tt.id and mm.active),'[]'::jsonb)) order by tt.parallel,tt.group_number) from public.aula_teams tt join aula_private.fourth_portfolios pp on pp.team_id=tt.id where tt.grade=4 and(p_team is null or tt.id=p_team)),'[]'::jsonb));
end; $$;
revoke all on function public.aula_fourth_workspace(uuid,jsonb,bigint,jsonb) from public,anon;
grant execute on function public.aula_fourth_workspace(uuid,jsonb,bigint,jsonb) to authenticated;
create function public.aula_fourth_enter(p_name text,p_parallel text,p_group integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); member uuid; matches integer;
begin
 if uid is null or not exists(select 1 from auth.users where id=uid and is_anonymous) then raise exception 'Sesión estudiantil requerida'; end if;
 update public.aula_enrollments set active=false where auth_user_id=uid;
 if p_name is null or length(btrim(p_name)) not between 4 and 120 or p_parallel is null or p_parallel not in('A','B','C') or p_group is null or p_group not between 1 and 5 then return jsonb_build_object('status','not_member'); end if;
 select count(*),(array_agg(m.id))[1] into matches,member from public.aula_members m join public.aula_teams t on t.id=m.team_id where t.grade=4 and t.parallel=p_parallel and t.group_number=p_group and m.active and aula_private.coincide_nombre(m.full_name,p_name);
 if matches<>1 then return jsonb_build_object('status','not_member'); end if;
 insert into public.aula_enrollments(auth_user_id,member_id,active,approved_at) values(uid,member,true,now()) on conflict(auth_user_id) do update set member_id=excluded.member_id,active=true,approved_at=now();
 return jsonb_build_object('status','ok');
end; $$;
revoke all on function public.aula_fourth_enter(text,text,integer) from public,anon;
grant execute on function public.aula_fourth_enter(text,text,integer) to authenticated;
create function public.aula_fourth_snapshot()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare tid uuid:=aula_private.equipo_estudiante(); t public.aula_teams; p aula_private.fourth_portfolios; m public.aula_members; d jsonb;
begin
 select * into t from public.aula_teams where id=tid and grade=4;
 if not found then return jsonb_build_object('status','no_enrollment'); end if;
 select mm.* into m from public.aula_members mm join public.aula_enrollments e on e.member_id=mm.id where e.auth_user_id=auth.uid() and e.active;
 select * into p from aula_private.fourth_portfolios where team_id=tid;
 d:=p.data;
 if d->'activity' is not null then d:=jsonb_set(d,'{activity,individual}',jsonb_build_object(m.full_name,coalesce(d->'activity'->'individual'->m.full_name,'{}'::jsonb))); end if;
 return jsonb_build_object('status','ok','user',jsonb_build_object('name',m.full_name,'grade',4),'team',jsonb_build_object('id',t.id,'parallel',t.parallel,'group',t.group_number,'color',t.color_hex,'colorName',t.color_name,'data',d,'version',p.version,'updatedAt',p.updated_at,'members',coalesce((select jsonb_agg(jsonb_build_object('name',full_name,'role',role_name) order by full_name) from public.aula_members where team_id=tid and active),'[]'::jsonb)));
end; $$;
revoke all on function public.aula_fourth_snapshot() from public,anon;
grant execute on function public.aula_fourth_snapshot() to authenticated;
-- Protege cuarto también frente a endpoints de escritura antiguos.
create function aula_private.fourth_readonly_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare tid uuid;
begin
 if tg_table_name='aula_teams' then tid:=new.id; else tid:=new.team_id; end if;
 if auth.uid() is not null and not public.aula_is_teacher() and exists(select 1 from public.aula_teams where id=tid and grade=4) then raise exception 'Cuarto es de solo consulta. La docente registra los cambios'; end if;
 return new;
end; $$;
revoke all on function aula_private.fourth_readonly_guard() from public,anon,authenticated;
create trigger fourth_readonly before update on public.aula_teams for each row execute function aula_private.fourth_readonly_guard();
create trigger fourth_readonly before insert or update on public.aula_works for each row execute function aula_private.fourth_readonly_guard();
create trigger fourth_readonly before insert or update on public.aula_portfolios for each row execute function aula_private.fourth_readonly_guard();
