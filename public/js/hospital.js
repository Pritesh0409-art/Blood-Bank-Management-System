const h=guard('hospital');nav('hospital');
$('#hn').textContent=h.name;$('#hi').textContent=`Hospital ID ${h.hospital_id} · ${h.contact_no} · ${h.address||''}`;
$('#rg').innerHTML=opts(GROUPS);$('#rc').innerHTML=opts(COMPS);
async function compat(){const c=await api(`compat?group=${encodeURIComponent($('#rg').value)}&component=${encodeURIComponent($('#rc').value)}`);
 $('#cg').innerHTML=c.groups.map(g=>tag(g)).join(' ');$('#cs').textContent=c.stock+' units'}
async function load(){const d=await api('hospital/'+h.hospital_id);
 table('#reqs',[['Req',r=>'#'+r.request_id],['Date',r=>r.request_date],['Group',r=>`<b>${r.blood_group_needed}</b>`],['Component',r=>r.component_type],['Issued / Qty',r=>`${r.issued} / ${r.quantity_required}`],['Urgency',r=>tag(r.urgency_level)],['Status',r=>tag(r.status)]],d.requests);
 table('#issues',[['Issue',r=>'#'+r.issue_id],['Request',r=>'#'+r.request_id],['Unit',r=>'#'+r.unit_id],['Group',r=>r.blood_group],['Component',r=>r.component_type],['Issued by',r=>esc(r.issued_by)],['Date',r=>r.issue_date]],d.issues)}
['#rg','#rc'].forEach(s=>$(s).onchange=compat);
$('#fr').onsubmit=async e=>{e.preventDefault();try{const r=await api('requests',{...Object.fromEntries(new FormData(e.target)),hospital_id:h.hospital_id});toast('Request #'+r.request_id+' submitted');load()}catch(x){toast(x.message,1)}};
compat();load();
