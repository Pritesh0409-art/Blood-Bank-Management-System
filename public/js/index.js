nav('home');let P;
const campsHtml=cs=>cs.map(c=>{const p=Math.min(100,Math.round(c.collected/c.target_units*100));return`<div class="card"><b>${esc(c.location)}</b><br>${c.camp_date} · ${esc(c.organizer)}<br>Camp #${c.camp_id}<p>${c.collected} / ${c.target_units} units</p><div class="bar"><i style="width:${p}%"></i></div></div>`}).join('');
function setRole(){const r=$('#role').value;const pick=r!=='donor';$('#pick').style.display=pick?'':'none';$('#idin').style.display=pick?'none':'';
 $('#idlabel').textContent={staff:'Staff member',hospital:'Hospital',donor:'Donor ID or mobile number'}[r];
 if(r==='staff')$('#pick').innerHTML=opts(P.staff,s=>[s.staff_id,`${s.name} (${s.role})`]);if(r==='hospital')$('#pick').innerHTML=opts(P.hospitals,h=>[h.hospital_id,h.name])}
(async()=>{P=await api('public');
 $('#stock').innerHTML=P.stock.map(s=>`<div class="card stat ${s.available_units<5?'low':''}"><h2>${s.blood_group}</h2><b>${s.available_units}</b>${s.available_units<5?'Critical (&lt;5)':'Adequate'}</div>`).join('');
 $('#camps').innerHTML=campsHtml(P.camps);setRole();$('#role').onchange=setRole;
 $('#go').onclick=async()=>{const role=$('#role').value,id=role==='donor'?$('#idin').value.trim():$('#pick').value;
  try{const user=await api('login',{role,id});
   if(role==='donor'){const d=await api('donor/'+user.donor_id);const x=d.donor;
    $('#donorcard').innerHTML=`<h2>Donor Card: ${esc(x.name)} (#${x.donor_id})</h2><p>${x.blood_group} · ${x.gender} · ${x.age} yrs · ${x.weight} kg · ${esc(x.address||'')}<br>Last donation: ${x.last_donation_date||'none'} — ${x.eligible&&x.weight>=45?tag('Eligible to donate','yes'):tag('Not yet eligible','low-t')}</p><div id="hist"></div>`;
    table('#hist',[['Donation',r=>'#'+r.donation_id],['Date',r=>r.donation_date],['ml',r=>r.quantity_ml],['Screening',r=>tag(r.screening_result)]],d.history);return}
   sessionStorage.bbms=JSON.stringify({role,user});location.href=role==='staff'?'staff.html':'hospital.html'}catch(e){toast(e.message,1)}}})();
