/* Navegación adaptable: conserva las acciones y rutas de cada módulo. */
(()=>{
'use strict';
const colors={4:'#e7b749',5:'#2d9b70',6:'#ed9b46',7:'#db79a4'};
function decorate(grade){
 deckHome.classList.add('portalNavigation');
 deckHome.classList.toggle('portalWeekMenu',!!deckHome.querySelector('.deckWeeks'));
 deckHome.classList.toggle('portalFolderMenu',!!deckHome.querySelector('.deckCourseGrid'));
 deckHome.style.setProperty('--portal-course',colors[grade]||'#138da1');
 deckHome.querySelectorAll('[data-deckcourse]').forEach(button=>{const color=colors[button.dataset.deckcourse];if(color)button.style.setProperty('--accent',color)});
 const icons=[
  ['[data-deckcourse="4"]','cuarto'],['[data-deckcourse="5"]','quinto'],
  ['[data-deckcourse="6"]','6'],['[data-deckcourse="7"]','7'],
  ['[data-deckcourse="dt"]','design-thinking'],['[data-odsopen]','ods'],
  ['[data-ev-open]','evaluacion'],['[data-portal-project]','proyecto-v1'],['[data-equipos-open]','equipos']
 ];
 for(const [selector,key] of icons){
  const slot=deckHome.querySelector(selector+' > span');if(!slot)continue;
  slot.classList.remove('odsHomeRing');slot.setAttribute('aria-hidden','true');
  const img=document.createElement('img');img.src='iconos-cursos/carpeta-'+key+'.webp';
  img.className='portalRealCourseIcon';img.alt='';img.width=96;img.height=96;
  slot.replaceChildren(img);
 }
 const weeks=deckHome.querySelector('.deckWeeks');
 if(weeks){
  weeks.style.setProperty('--portal-columns',weeks.children.length>4?3:4);
  weeks.querySelectorAll('[data-deckdt] > span').forEach((slot,i)=>{
   const image=document.createElement('img');image.src='iconos-cursos/carpeta-'+['design-thinking','cuarto','quinto','6','7'][i]+'.webp';
   image.alt='';image.className='portalRealCourseIcon';slot.setAttribute('aria-hidden','true');slot.replaceChildren(image);
  });
  weeks.querySelectorAll(':scope > article').forEach(article=>{
   if(!article.querySelector(':scope > span')){const label=document.createElement('span');label.className='portalWeekLabel';label.textContent='Planificación';article.prepend(label)}
  });
 }
}
const previousStart=deckStart;
deckStart=function(grade){const result=previousStart.apply(this,arguments);decorate(grade);return result};
const previousHome=deckShowHome;
deckShowHome=function(){const result=previousHome.apply(this,arguments);decorate();return result};
decorate();
})();
