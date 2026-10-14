const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
async function api(url,body){const r=await fetch('/api/'+url,body?{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}:{});
 const d=await r.json();if(!r.ok)throw new Error(d.error||'Request failed');return d}
function table(sel,cols,rows){$(sel).innerHTML=`<table><thead><tr>${cols.map(c=>`<th>${c[0]}</th>`).join('')}</tr></thead><tbody>${
 rows.map(r=>`<tr>${cols.map(c=>`<td>${c[1](r)}</td>`).join('')}</tr>`).join('')||`<tr><td colspan="${cols.length}">No records</td></tr>`}</tbody></table>`}
function toast(m,err){const t=$('#toast');t.textContent=m;t.className=err?'err':'';t.style.display='block';clearTimeout(t.t);t.t=setTimeout(()=>t.style.display='none',4500)}
const tag=(v,c)=>`<span class="tag ${c||v}">${esc(v)}</span>`;
const session=()=>JSON.parse(sessionStorage.bbms||'null');
function guard(role){const s=session();if(!s||s.role!==role){location.href='index.html';return null}return s.user}
function nav(active){const s=session();$('header').innerHTML=`<div><b>BBMS</b> Blood Bank Management</div><nav>
 <a href="index.html" class="${active==='home'?'on':''}">Home / Login</a>${s?.role==='staff'?`<a href="staff.html" class="${active==='staff'?'on':''}">Staff Dashboard</a><a href="intake.html" class="${active==='intake'?'on':''}">Donor Intake</a>`:''}${s?.role==='hospital'?'<a href="hospital.html" class="on">Hospital Portal</a>':''}
 ${s?`<a href="#" onclick="sessionStorage.clear();location.href='index.html'">Logout (${esc(s.user.name)})</a>`:''}</nav>`}
const GROUPS=['A+','A-','B+','B-','AB+','AB-','O+','O-'],COMPS=['Whole Blood','RBC','Plasma','Platelets'];
const opts=(a,f=x=>[x,x])=>a.map(x=>`<option value="${esc(f(x)[0])}">${esc(f(x)[1])}</option>`).join('');
