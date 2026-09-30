
/* Explicit save/edit controls. Saved teams persist per course in this browser. */
const teamsEditing=new Set();
const teamsViewKey=()=>activeGrade===4?'4'+course:String(activeGrade)+(g57State.course||'A');
const teamsStorageKey=()=>activeGrade===4?s2TeamsKey():g57Key();
function teamsEditControls(){
 const key=teamsViewKey(),isFour=activeGrade===4,root=document.getElementById(isFour?'stage':'otherGradeContent'),toolbar=root?.querySelector(isFour?'.teamControls':'.eqTools');
 const state=isFour?s2State():eqState();if(!toolbar||!state)return;
 let controls=toolbar.querySelector('[data-teams-save-controls]');
 if(!controls){controls=document.createElement('div');controls.dataset.teamsSaveControls='';controls.className='controls';controls.innerHTML='<button class="action primary" data-teams-edit>✏️ Editar equipos</button><button class="action saveImage" data-teams-save>💾 Guardar cambios</button><button class="action" data-teams-backup>⬇ Copia de seguridad</button><label class="action" style="cursor:pointer">↥ Recuperar equipos<input type="file" data-teams-restore accept=".json" style="display:none"></label><span class="progress" data-teams-save-status role="status"></span>';toolbar.prepend(controls)}
 const editing=teamsEditing.has(key);controls.querySelector('[data-teams-edit]').hidden=editing;controls.querySelector('[data-teams-save]').hidden=!editing;
 const mark=localStorage.getItem('teams-saved-'+key);
 const msg=editing?'Editando · pulsa Guardar cambios':mark?'✓ Guardados · '+new Date(mark).toLocaleString('es-EC'):'Equipos recuperados · pulsa Editar para hacer cambios';
 const status=controls.querySelector('[data-teams-save-status]');if(status.textContent!==msg)status.textContent=msg;
 root.querySelectorAll('.teamCard input,.teamCard select,#s2Count,#s2Reshuffle,#eqCount,[data-eq-create],[data-eq-participant],#eqImport,#s2Import').forEach(el=>{if(el.disabled===editing)el.disabled=!editing});
}
function teamsBackup(){
 const data={format:'emprendimiento-equipos-v1',savedAt:new Date().toISOString(),storage:{}};
 for(let i=0;i<localStorage.length;i++){const key=localStorage.key(i);if(/^(ea-cuarto-[ABC]-(lista-privada|equipos-semana4)|emprendimiento-g57-[567]-[ABC]-s1|eq57-listas|teams-saved-[4567][ABC])$/.test(key))data.storage[key]=localStorage.getItem(key)}
 const blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='equipos-emprendimiento-respaldo.json';document.body.append(a);a.click();a.remove();URL.revokeObjectURL(url);
}
document.addEventListener('click',e=>{
 const b=e.target.closest('button');if(!b)return;
 if(b.id==='s2Create'||b.id==='s2Reshuffle'||b.dataset.eqCreate!==undefined){teamsEditing.add(teamsViewKey());return}
 if(b.dataset.teamsEdit!==undefined){teamsEditing.add(teamsViewKey());teamsEditControls()}
 if(b.dataset.teamsSave!==undefined){try{const key=teamsStorageKey(),value=localStorage.getItem(key);if(!value)throw Error('No hay equipos para guardar');localStorage.setItem(key,value);if(localStorage.getItem(key)!==value)throw Error('No se pudo comprobar el guardado');localStorage.setItem('teams-saved-'+teamsViewKey(),new Date().toISOString());teamsEditing.delete(teamsViewKey());activeGrade===4?render():renderG57();teamsEditControls()}catch(err){const msg=document.querySelector('[data-teams-save-status]');if(msg)msg.textContent='No se pudo guardar: '+err.message}}
 if(b.dataset.teamsBackup!==undefined)teamsBackup();
},true);
document.addEventListener('change',async e=>{
 if(e.target.dataset.teamsRestore===undefined)return;
 try{const data=JSON.parse(await e.target.files[0].text());if(data.format!=='emprendimiento-equipos-v1'||typeof data.storage!=='object')throw Error('Selecciona una copia de seguridad de equipos.');const entries=Object.entries(data.storage);for(const [key,value]of entries){if(!/^(ea-cuarto-[ABC]-(lista-privada|equipos-semana4)|emprendimiento-g57-[567]-[ABC]-s1|eq57-listas|teams-saved-[4567][ABC])$/.test(key)||typeof value!=='string')throw Error('Archivo de respaldo no válido.');if(!key.startsWith('teams-saved-'))JSON.parse(value)}for(const [key,value]of entries)localStorage.setItem(key,value);teamsEditing.clear();activeGrade===4?render():renderG57();teamsEditControls();}catch(err){alert('No se pudieron recuperar los equipos: '+err.message)}
});
const teamsSaveObserver=new MutationObserver(()=>teamsEditControls());teamsSaveObserver.observe(document.getElementById('stage'),{childList:true,subtree:true});teamsSaveObserver.observe(document.getElementById('otherGradeContent'),{childList:true,subtree:true});
teamsEditControls();
