/* Datos docentes en Supabase. Ninguna operación cae silenciosamente al modo local. */
(function(w){'use strict';
function create(client,A){
 const local={context:A.context,groupIds:A.groupIds,team:A.team,work:A.work,portfolio:A.portfolio,grades:A.grades,publication:A.publication,project:A.project,receipt:A.receipt};
 let cache={teams:[],members:[],publications:[],works:[],portfolios:[],groupGrades:[],individualGrades:[]},loaded='',generation=0,reviewReady=false,evaluations=[];
 const contextKey=(g,p)=>`${g}-${p}`;
 const result=async query=>{const {data,error}=await query;if(error)throw Error(error.message||'La base de datos no respondió.');return data;};
 const sourceTeam=c=>cache.teams.find(t=>t.grade===c.grade&&t.parallel===c.parallel&&t.group_number===c.group);
 const sourcePub=c=>cache.publications.find(p=>p.grade===c.grade&&p.parallel===c.parallel&&(c.publicationId?p.id===c.publicationId:p.week_number===8));
 const assertReady=c=>{if(loaded!==contextKey(c.grade,c.parallel)||!sourceTeam(c)||!sourcePub(c))throw Error('Primero carga este paralelo desde la base de datos.');};
 const memberRows=c=>{const t=sourceTeam(c);return t?cache.members.filter(m=>m.team_id===t.id&&m.active):[];};
 const blankWork=()=>({ods:[null,null,null,null],reasons:['','','',''],principal:0,indicator:'',status:'draft',savedAt:null,submittedAt:null});
 function project(c){const original=local.project(c),t=sourceTeam(c);return t?{...original,title:t.project_title,official:t.project_description||original?.official,problem:t.project_problem||'',solution:t.project_solution||''}:original;}
 function team(c){const t=sourceTeam(c),fallback=local.team(c);return {name:t?.team_name||'',norm:t?.agreement||'',members:memberRows(c).map(m=>({id:m.id,name:m.full_name,role:m.role_name||'Rol por confirmar'})),color:t?.color_hex||fallback.color,colorName:t?.color_name||fallback.colorName,project:project(c)};}
 function work(c){const t=sourceTeam(c),p=sourcePub(c),r=cache.works.find(x=>x.team_id===t?.id&&x.publication_id===p?.id);return r?{...blankWork(),...r.content,status:r.status,savedAt:r.updated_at,submittedAt:r.submitted_at}:blankWork();}
 function portfolio(c){const r=cache.portfolios.find(x=>x.team_id===sourceTeam(c)?.id);return r?{url:r.shared_url,app:r.app,updatedAt:r.updated_at}:{url:'',app:'Pages',updatedAt:null};}
 function grades(c){const t=sourceTeam(c),p=sourcePub(c),r=cache.groupGrades.find(x=>x.team_id===t?.id&&x.publication_id===p?.id),members={};for(const m of memberRows(c)){const score=cache.individualGrades.find(x=>x.member_id===m.id&&x.publication_id===p?.id);members[m.full_name]=score?.contribution_score??null;}return {ods:r?.ods_score??null,reasons:r?.reasons_score??null,members,comment:r?.feedback||'',savedAt:r?.updated_at||null};}
 async function load(g,p){const revision=++generation;loaded='';cache={teams:[],members:[],publications:[],works:[],portfolios:[],groupGrades:[],individualGrades:[]};
  let teams=await result(client.from('aula_teams').select('*').eq('grade',g).eq('parallel',p));
  const missing=A.groupIds(g,p).filter(n=>!teams.some(t=>t.group_number===n)).map(n=>{const c=A.context(g,p,n),s=local.team(c);return {grade:g,parallel:p,group_number:n,color_name:s.colorName,color_hex:s.color,project_title:s.project.title,project_description:s.project.official||'',team_name:''};});
  if(missing.length){try{await result(client.from('aula_teams').insert(missing));}catch(e){if(!/duplicate|unique/i.test(e.message))throw e;}teams=await result(client.from('aula_teams').select('*').eq('grade',g).eq('parallel',p));}
  const ids=teams.map(t=>t.id),pubs=await result(client.from('aula_publications').select('*').eq('grade',g).eq('parallel',p));
  if(!pubs.some(x=>x.week_number===8))throw Error('No se encontró la actividad semanal. Revisa el script de preparación.');
  const publication=pubs.find(x=>x.week_number===8);
  const [members,works,portfolios,groupGrades]=await Promise.all([
   result(client.from('aula_members').select('*').in('team_id',ids)),
   result(client.from('aula_works').select('*').in('team_id',ids)),
   result(client.from('aula_portfolios').select('*').in('team_id',ids)),
   result(client.from('aula_group_grades').select('*').in('team_id',ids))
  ]);
  const individualGrades=members.length?await result(client.from('aula_individual_grades').select('*').in('member_id',members.map(m=>m.id))):[];
  let nextEvaluations=[],nextReviewReady=false;try{nextEvaluations=await result(client.from('aula_evaluations').select('*').in('team_id',ids));nextReviewReady=true;}catch(err){if(!/aula_evaluations|schema cache|could not find|does not exist/i.test(err.message))throw err;}
  if(revision!==generation)return;evaluations=nextEvaluations;reviewReady=nextReviewReady;cache={teams,members,publications:pubs,works,portfolios,groupGrades,individualGrades};loaded=contextKey(g,p);
 }
 async function publish(g,p,state,publicationId=null){const c={...A.context(g,p,1),publicationId};assertReady(c);if(!['draft','available','closed'].includes(state))throw Error('Disponibilidad no válida.');const rows=await result(client.from('aula_publications').update({state,updated_at:new Date().toISOString()}).eq('id',sourcePub(c).id).select('*'));if(rows.length!==1)throw Error('No se guardó la disponibilidad. Comprueba tu sesión.');cache.publications=cache.publications.map(p=>p.id===rows[0].id?rows[0]:p);}
 async function saveGrades(c,v){assertReady(c);const valid=(n,max)=>n===null||Number.isInteger(n)&&n>=0&&n<=max;if(!valid(v.ods,4)||!valid(v.reasons,4)||Object.values(v.members||{}).some(n=>!valid(n,2)))throw Error('Revisa los puntajes: 4 + 4 + 2.');const members=memberRows(c);if(Object.keys(v.members||{}).some(n=>!members.some(m=>m.full_name===n)))throw Error('Los integrantes cambiaron. Actualiza el paralelo antes de evaluar.');const t=sourceTeam(c),p=sourcePub(c),now=new Date().toISOString();
  const groupRows=await result(client.from('aula_group_grades').upsert({team_id:t.id,publication_id:p.id,ods_score:v.ods,reasons_score:v.reasons,feedback:String(v.comment||'').slice(0,500),updated_at:now},{onConflict:'team_id,publication_id'}).select('*'));if(groupRows.length!==1)throw Error('No se guardaron los criterios grupales.');
  const rows=members.map(m=>({member_id:m.id,publication_id:p.id,contribution_score:v.members[m.full_name]??null,updated_at:now}));
  try{if(rows.length){const saved=await result(client.from('aula_individual_grades').upsert(rows,{onConflict:'member_id,publication_id'}).select('*'));if(saved.length!==rows.length)throw Error('Faltan aportes individuales.');}}catch{await load(c.grade,c.parallel);throw Error('Los criterios grupales se guardaron, pero falta completar el aporte individual. Revisa y vuelve a guardar.');}
  await load(c.grade,c.parallel);
 }
 function validateTeam(c,v){assertReady(c);if(typeof v.project!=='string'||!v.project.trim()||v.project.length>500||typeof v.name!=='string'||v.name.length>120)throw Error('Completa el tema y revisa el nombre del equipo.');if(!Array.isArray(v.members)||v.members.length>40)throw Error('Revisa la lista de integrantes.');const clean=v.members.filter(m=>String(m.name||'').trim()).map(m=>({id:m.id||null,name:m.name.trim().replace(/\s+/g,' '),role:String(m.role||'').trim()}));const seen=new Set();for(const m of clean){if(m.name.length<3||m.name.length>120||m.role.length>100)throw Error('Revisa nombres y roles.');const id=A.ident(m.name);if(seen.has(id))throw Error('Hay un nombre repetido en el equipo.');seen.add(id);if(m.id&&!cache.members.some(x=>x.id===m.id))throw Error('Identificador de integrante no válido.');}return {...v,members:clean};}
 async function saveTeam(c,value){const v=validateTeam(c,value),t=sourceTeam(c),now=new Date().toISOString(),kept=[];
  const rows=await result(client.from('aula_teams').update({team_name:v.name.trim(),project_title:v.project.trim(),agreement:String(v.norm??t.agreement??'').slice(0,500),...(reviewReady?{project_problem:String(v.problem??t.project_problem??'').slice(0,1000),project_solution:String(v.solution??t.project_solution??'').slice(0,1000)}:{}),updated_at:now}).eq('id',t.id).select('*'));if(rows.length!==1)throw Error('No se guardó el equipo.');
  for(const m of v.members){let old=m.id?cache.members.find(x=>x.id===m.id):cache.members.find(x=>A.ident(x.full_name)===A.ident(m.name));if(old){const changed=await result(client.from('aula_members').update({team_id:t.id,full_name:m.name,role_name:m.role,active:true,updated_at:now}).eq('id',old.id).select('*'));if(changed.length!==1)throw Error('No se guardó un integrante.');kept.push(old.id);}else{const added=await result(client.from('aula_members').insert({team_id:t.id,full_name:m.name,role_name:m.role,active:true,updated_at:now}).select('*'));if(added.length!==1)throw Error('No se incorporó un integrante.');kept.push(added[0].id);}}
  const removed=cache.members.filter(m=>m.team_id===t.id&&m.active&&!kept.includes(m.id));if(removed.length)await result(client.from('aula_members').update({active:false,updated_at:now}).in('id',removed.map(m=>m.id)));
  await load(c.grade,c.parallel);
 }
 async function importLocal(g,p){const groups=A.groupIds(g,p).map(n=>{const c=A.context(g,p,n);return {c,team:local.team(c)};}).filter(x=>x.team.members.length);if(!groups.length)throw Error('No hay integrantes guardados en este navegador. Puedes añadirlos desde Revisar equipo.');const names=new Set();for(const {team} of groups)for(const m of team.members){const n=A.ident(m.name);if(names.has(n))throw Error('La distribución local repite un integrante. Corrígela en Equipos antes de importar.');names.add(n);}
  for(const {c,team:t} of groups)await saveTeam(c,{name:t.name,project:sourceTeam(c)?.project_title||t.project.title,norm:t.norm,members:t.members.map(m=>({name:m.name,role:m.role}))});
  return groups.reduce((sum,x)=>sum+x.team.members.length,0);
 }
 function evaluation(c){const r=evaluations.find(x=>x.team_id===sourceTeam(c)?.id&&x.publication_id===sourcePub(c)?.id);return {ods:r?.ods_score??null,reasons:r?.reasons_score??null,teamwork:r?.teamwork_score??null,members:r?.individual_scores||{},comment:r?.feedback||'',savedAt:r?.updated_at||null};}
 async function saveEvaluation(c,value){assertReady(c);if(!reviewReady)throw Error('Instala el paso 4 para guardar la nueva rúbrica.');const {data,error}=await client.rpc('aula_teacher_save_evaluation',{p_team:sourceTeam(c).id,p_publication:sourcePub(c).id,p_values:value});if(error)throw Error(error.message);if(!data?.team_id)throw Error('No se confirmó el guardado de la evaluación.');await load(c.grade,c.parallel);}
 function publications(){return [...cache.publications].sort((a,b)=>b.week_number-a.week_number);}
 function groupIds(g,p){return loaded===contextKey(g,p)?cache.teams.map(x=>x.group_number).sort((a,b)=>a-b):local.groupIds(g,p);}
 function context(g,p,n){return loaded===contextKey(+g,p)&&cache.teams.some(t=>t.group_number===+n)?{grade:+g,parallel:p,group:+n}:local.context(g,p,n);}
 function install(){Object.assign(A,{context,groupIds,team,project,work,portfolio,grades,publication:(g,p)=>cache.publications.find(x=>x.grade===g&&x.parallel===p&&x.week_number===8)?.state||'draft',publish,saveGrades,receipt:c=>({format:'ea-aula-evidencia-w8-v1',context:c,project:project(c)?.title,activity:work(c),portfolio:portfolio(c)})});}
 const clear=()=>{++generation;reviewReady=false;evaluations=[];cache={teams:[],members:[],publications:[],works:[],portfolios:[],groupGrades:[],individualGrades:[]};loaded='';};
 return {load,install,clear,evaluation,saveEvaluation,publications,reviewReady:()=>reviewReady,saveTeam,importLocal,local,ready:c=>loaded===contextKey(c.grade,c.parallel)};
}
w.AulaCloud={create};
})(window);
