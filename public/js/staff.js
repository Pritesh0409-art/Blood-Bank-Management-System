const me=guard('staff');nav('staff');let D,cur;
const dlg=$('#dlg');
function units(){const s=$('#srch').value.toLowerCase(),g=$('#fg').value,st=$('#fs').value;
 table('#units',[['Unit',r=>'#'+r.unit_id],['Donor',r=>esc(r.donor_name)],['Group',r=>`<b>${r.blood_group}</b>`],['Component',r=>r.component_type],['Collected',r=>r.collection_date],['Expiry',r=>r.expiry_date],['Days left',r=>r.status==='Available'?r.days_left:'—'],['Status',r=>tag(r.status)]],
 D.units.filter(u=>(!g||u.blood_group===g)&&(!st||u.status===st)&&(!s||('#'+u.unit_id+u.donor_name).toLowerCase().includes(s))))}
async function load(){D=await api('staff-dash');const k=D.kpi;
 $('#kpi').innerHTML=[['Available units',k.available],['Open requests',k.pending],['Registered donors',k.donors],['Eligible donors now',k.eligible],['Expiring ≤10 days',k.near_expiry]].map(x=>`<div class="card k">${x[0]}<b>${x[1]}</b></div>`).join('');
 table('#reqs',[['Req',r=>'#'+r.request_id],['Hospital',r=>esc(r.hospital_name)],['Group',r=>`<b>${r.blood_group_needed}</b>`],['Component',r=>r.component_type],['Issued / Qty',r=>`${r.issued} / ${r.quantity_required}`],['Urgency',r=>tag(r.urgency_level)],['Date',r=>r.request_date],['Status',r=>tag(r.status)],['',r=>`<button onclick="openIssue(${r.request_id})">Issue</button>`]],D.requests);
 table('#issues',[['Issue',r=>'#'+r.issue_id],['Request',r=>'#'+r.request_id],['Donor',r=>esc(r.donor_name)],['Unit',r=>'#'+r.unit_id],['Group',r=>r.blood_group],['Component',r=>r.component_type],['Hospital',r=>esc(r.hospital_name)],['Issued by',r=>esc(r.issued_by)],['Date',r=>r.issue_date]],D.issues);units()}
async function openIssue(id){cur=id;const u=await api(`request/${id}/units`);
 $('#dt').textContent='Issue unit for request #'+id;$('#du').innerHTML=u.length?opts(u,x=>[x.unit_id,`Unit #${x.unit_id} · ${x.blood_group} ${x.component_type} · exp ${x.expiry_date}`]):'<option value="">No compatible units available</option>';dlg.showModal()}
$('#dok').onclick=async()=>{try{if(!$('#du').value)throw Error('No unit selected');const r=await api('issues',{request_id:cur,unit_id:$('#du').value,staff_id:$('#ds').value});dlg.close();toast(`Issued (#${r.issue_id}). Request is now ${r.request_status}`);load()}catch(e){toast(e.message,1)}};
['#srch','#fg','#fs'].forEach(s=>$(s).oninput=()=>units());
(async()=>{const P=await api('public');$('#fg').innerHTML+=opts(GROUPS);$('#ds').innerHTML=opts(P.staff,s=>[s.staff_id,`${s.name} (${s.role})`]);$('#ds').value=me.staff_id;
 $('#camps').innerHTML=P.camps.map(c=>`<div class="card"><b>${esc(c.location)}</b><br>${c.camp_date} · ${esc(c.organizer)}<p>${c.collected} / ${c.target_units} units</p><div class="bar"><i style="width:${Math.min(100,c.collected/c.target_units*100)}%"></i></div></div>`).join('');load()})();
