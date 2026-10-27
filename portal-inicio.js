/* Carpeta de Proyecto V1 y zoom de entrada, conservando las rutas del portal. */
(()=>{
'use strict';
const reduced=()=>window.matchMedia('(prefers-reduced-motion: reduce)').matches;
function addProjectFolder(){
 const grid=deckHome.querySelector('.deckCourseGrid');
 if(!grid||grid.querySelector('[data-portal-project]'))return;
 grid.insertAdjacentHTML('beforeend','<button data-portal-project style="--accent:#10a9b4"><span aria-hidden="true">📂</span><b>Presentación de Proyecto V1</b><small>Demo Day · Quinto a séptimo</small><strong>Entrar →</strong></button>');
}
function addRealCourseIcons(){
 for(const grade of [6,7]){
  const slot=deckHome.querySelector('[data-deckcourse="'+grade+'"] > span');
  if(!slot)continue;
  slot.setAttribute('aria-hidden','true');
  const image=document.createElement('img');
  image.src='iconos-cursos/carpeta-'+grade+'.webp';
  image.alt='';image.className='portalRealCourseIcon';image.width=96;image.height=96;
  slot.replaceChildren(image);
 }
}
const previousHome=deckShowHome;
deckShowHome=function(){const result=previousHome.apply(this,arguments);addProjectFolder();addRealCourseIcons();return result};
addProjectFolder();
addRealCourseIcons();
let activeLayer=null;
function zoom(button){
 if(reduced())return;
 if(activeLayer)activeLayer.remove();
 const rect=button.getBoundingClientRect();
 if(!rect.width||!rect.height)return;
 const layer=document.createElement('div');layer.className='portalZoomLayer';layer.setAttribute('aria-hidden','true');
 const icon=button.querySelector(':scope > span'),title=button.querySelector(':scope > b,:scope > h2,:scope > strong');
 if(icon){layer.append(icon.cloneNode(true))}
 const text=document.createElement('b');text.textContent=title?.textContent||button.textContent;layer.append(text);
 Object.assign(layer.style,{left:rect.left+'px',top:rect.top+'px',width:rect.width+'px',height:rect.height+'px'});
 layer.style.setProperty('--portal-accent',getComputedStyle(button).getPropertyValue('--accent')||'#008fa5');
 document.body.append(layer);activeLayer=layer;
 const dx=innerWidth/2-(rect.left+rect.width/2),dy=innerHeight/2-(rect.top+rect.height/2);
 const scale=Math.max(innerWidth/rect.width,innerHeight/rect.height)*1.08;
 const animation=layer.animate([{transform:'translate(0,0) scale(1)',opacity:1},{transform:'translate('+dx+'px,'+dy+'px) scale('+scale+')',opacity:.95,offset:.7},{transform:'translate('+dx+'px,'+dy+'px) scale('+scale+')',opacity:0}],{duration:560,easing:'cubic-bezier(.22,.7,.2,1)',fill:'forwards'});
 animation.finished.catch(()=>{}).finally(()=>{layer.remove();if(activeLayer===layer)activeLayer=null});
}
const entries='[data-deckcourse],[data-deckweek],[data-deckdt],[data-odsopen],[data-ev-open],[data-ev-grade],[data-ev-parallel],[data-w8-open],[data-portal-project],[data-equipos-open],[data-ep="course"]';
window.addEventListener('click',event=>{
 const button=event.target.closest(entries);
 if(!button||button.disabled)return;
 zoom(button);
 if(button.hasAttribute('data-portal-project')){
  event.preventDefault();event.stopImmediatePropagation();
  setTimeout(()=>location.assign('presentacion-proyecto-v1-demo-day/'),reduced()?0:380);
 }
},true);
})();
