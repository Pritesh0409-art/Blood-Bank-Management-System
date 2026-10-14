guard('staff');nav('intake');
const f=e=>Object.fromEntries(new FormData(e.target));
async function load(){const[d,P]=await Promise.all([api('donors'),api('public')]);
 $('#dsel').innerHTML=opts(d,x=>[x.donor_id,`#${x.donor_id} ${x.name} (${x.blood_group}${x.eligible?'':', not eligible'})`]);
 $('#csel').innerHTML='<option value="">Walk-in / no camp</option>'+opts(P.camps,c=>[c.camp_id,`#${c.camp_id} ${c.location}`]);
 table('#donors',[['ID',r=>'#'+r.donor_id],['Name',r=>esc(r.name)],['Group',r=>`<b>${r.blood_group}</b>`],['Age',r=>r.age],['Weight',r=>r.weight+' kg'],['Gender',r=>r.gender],['Contact',r=>r.contact_no],['Address',r=>esc(r.address||'')],['Last donation',r=>r.last_donation_date||'—'],['Eligible',r=>r.eligible?tag('Yes','yes'):tag('No','low-t')]],d)}
$('#bg').innerHTML=opts(GROUPS);
$('#fd').onsubmit=async e=>{e.preventDefault();try{const r=await api('donors',f(e));toast('Donor registered with ID #'+r.donor_id);e.target.reset();load()}catch(x){toast(x.message,1)}};
$('#fn').onsubmit=async e=>{e.preventDefault();try{const r=await api('donations',f(e));toast(`Donation #${r.donation_id} saved`+(r.unit_id?`; blood unit #${r.unit_id} created`:' (no unit: not Fit)'));load()}catch(x){toast(x.message,1)}};
load();
