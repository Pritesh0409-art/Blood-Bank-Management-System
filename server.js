const express = require('express'), mysql = require('mysql2/promise');
const pool = mysql.createPool({ host: process.env.DB_HOST || 'localhost', user: process.env.DB_USER || 'root', password: process.env.DB_PASSWORD || '', database: 'blood_bank_db', dateStrings: true });
const app = express(); app.use(express.json()); app.use(express.static(__dirname + '/public'));
const q = async (s, p = []) => (await pool.query(s, p))[0];
const route = (m, p, f) => app[m]('/api/' + p, async (req, res) => {
  try { res.json(await f(req)) } catch (e) {
    res.status([1062, 3819, 1452, 1048, 1406, 1265].includes(e.errno) || e.sqlState === '45000' || e.user ? 400 : 500).json({ error: e.user || e.sqlMessage || e.message })
  }
});
const bad = m => ({ user: m });
const ISSUED = '(SELECT COUNT(*) FROM ISSUE_RECORD ir WHERE ir.request_id=br.request_id)';

route('get', 'public', async () => ({
  stock: await q(`SELECT bg.blood_group,COUNT(bu.unit_id) available_units FROM (SELECT DISTINCT donor_group blood_group FROM COMPATIBILITY) bg
  LEFT JOIN BLOOD_UNIT bu ON bu.blood_group=bg.blood_group AND bu.status='Available' AND bu.expiry_date>=CURDATE() GROUP BY bg.blood_group ORDER BY bg.blood_group`),
  camps: await q(`SELECT c.*,COUNT(CASE WHEN dn.screening_result='Fit' THEN 1 END) collected FROM CAMP c LEFT JOIN DONATION dn ON dn.camp_id=c.camp_id GROUP BY c.camp_id ORDER BY c.camp_date`),
  hospitals: await q('SELECT hospital_id,name FROM HOSPITAL ORDER BY name'),
  staff: await q('SELECT staff_id,name,role FROM STAFF ORDER BY staff_id')
}));

route('post', 'login', async r => {
  const { role, id } = r.body; if (!id) throw bad('Enter an identifier');
  const t = { staff: ['STAFF', 'staff_id'], hospital: ['HOSPITAL', 'hospital_id'], donor: ['DONOR', 'donor_id'] }[role];
  const rows = await q(`SELECT * FROM ${t[0]} WHERE ${t[1]}=? OR contact_no=?`, [id, id]);
  if (!rows.length) throw bad('No matching ' + role + ' record in the database'); return rows[0]
});

route('get', 'donor/:id', async r => {
  const [d] = await q(`SELECT *,DATEDIFF(CURDATE(),last_donation_date) days_since,
  (last_donation_date IS NULL OR DATEDIFF(CURDATE(),last_donation_date)>=IF(gender='Female',120,90)) eligible FROM DONOR WHERE donor_id=?`, [r.params.id]);
  return { donor: d, history: await q('SELECT * FROM donor_history_view WHERE donor_id=? ORDER BY donation_date', [r.params.id]) }
});

route('get', 'staff-dash', async () => {
  const [k] = await q(`SELECT (SELECT COUNT(*) FROM available_stock_view) available,(SELECT COUNT(*) FROM pending_requests_view) pending,
  (SELECT COUNT(*) FROM DONOR) donors,(SELECT COUNT(*) FROM DONOR WHERE weight>=45 AND (last_donation_date IS NULL OR DATEDIFF(CURDATE(),last_donation_date)>=IF(gender='Female',120,90))) eligible,
  (SELECT COUNT(*) FROM BLOOD_UNIT WHERE status='Available' AND DATEDIFF(expiry_date,CURDATE()) BETWEEN 0 AND 10) near_expiry`);
  return {
    kpi: k,
    requests: await q(`SELECT br.request_id,h.name hospital_name,br.blood_group_needed,br.component_type,br.quantity_required,br.urgency_level,br.request_date,br.status,${ISSUED} issued
   FROM BLOOD_REQUEST br JOIN HOSPITAL h ON h.hospital_id=br.hospital_id WHERE br.status IN ('Pending','Partially Fulfilled') ORDER BY FIELD(br.urgency_level,'Emergency','Routine'),br.request_date`),
    units: await q(`SELECT bu.unit_id,bu.blood_group,bu.component_type,bu.collection_date,bu.expiry_date,bu.status,DATEDIFF(bu.expiry_date,CURDATE()) days_left,d.name donor_name
   FROM BLOOD_UNIT bu JOIN DONATION dn ON dn.donation_id=bu.donation_id JOIN DONOR d ON d.donor_id=dn.donor_id ORDER BY bu.unit_id`),
    issues: await issues()
  }
});

const issues = (hid) => q(`SELECT ir.issue_id,ir.request_id,d.name donor_name,bu.unit_id,bu.blood_group,bu.component_type,h.name hospital_name,s.name issued_by,ir.issue_date
 FROM ISSUE_RECORD ir JOIN BLOOD_UNIT bu ON ir.unit_id=bu.unit_id JOIN DONATION dn ON bu.donation_id=dn.donation_id JOIN DONOR d ON dn.donor_id=d.donor_id
 JOIN BLOOD_REQUEST br ON ir.request_id=br.request_id JOIN HOSPITAL h ON br.hospital_id=h.hospital_id JOIN STAFF s ON ir.staff_id=s.staff_id
 ${hid ? 'WHERE h.hospital_id=?' : ''} ORDER BY ir.issue_date DESC,ir.issue_id DESC`, hid ? [hid] : []);

route('get', 'request/:id/units', r => q(`SELECT v.* FROM available_stock_view v JOIN BLOOD_REQUEST br ON br.request_id=? AND v.component_type=br.component_type
 JOIN COMPATIBILITY c ON c.recipient_group=br.blood_group_needed AND c.donor_group=v.blood_group ORDER BY v.expiry_date`, [r.params.id]));

route('get', 'compat', async r => {
  const { group, component } = r.query;
  const g = await q('SELECT donor_group FROM COMPATIBILITY WHERE recipient_group=? ORDER BY donor_group', [group]);
  const [n] = await q(`SELECT COUNT(*) n FROM available_stock_view WHERE component_type=? AND blood_group IN (SELECT donor_group FROM COMPATIBILITY WHERE recipient_group=?)`, [component, group]);
  return { groups: g.map(x => x.donor_group), stock: n.n }
});

route('get', 'hospital/:id', async r => ({
  requests: await q(`SELECT br.*,${ISSUED} issued FROM BLOOD_REQUEST br WHERE hospital_id=? ORDER BY request_id DESC`, [r.params.id]), issues: await issues(r.params.id)
}));

route('get', 'donors', () => q(`SELECT d.*,(d.weight>=45 AND (last_donation_date IS NULL OR DATEDIFF(CURDATE(),last_donation_date)>=IF(gender='Female',120,90))) eligible FROM DONOR d ORDER BY donor_id DESC`));

route('post', 'donors', async r => {
  const b = r.body;
  const x = await q('INSERT INTO DONOR(name,age,weight,gender,blood_group,contact_no,address) VALUES(?,?,?,?,?,?,?)', [b.name, b.age, b.weight, b.gender, b.blood_group, b.contact_no, b.address || null]); return { donor_id: x.insertId }
});
route('post', 'donations', async r => {
  const b = r.body;
  const x = await q('INSERT INTO DONATION(donor_id,camp_id,quantity_ml,screening_result) VALUES(?,?,?,?)', [b.donor_id, b.camp_id || null, b.quantity_ml, b.screening_result]);
  const u = await q('SELECT unit_id FROM BLOOD_UNIT WHERE donation_id=?', [x.insertId]); return { donation_id: x.insertId, unit_id: u[0]?.unit_id || null }
});
route('post', 'requests', async r => {
  const b = r.body;
  const x = await q('INSERT INTO BLOOD_REQUEST(hospital_id,blood_group_needed,component_type,quantity_required,urgency_level) VALUES(?,?,?,?,?)', [b.hospital_id, b.blood_group_needed, b.component_type, b.quantity_required, b.urgency_level]); return { request_id: x.insertId }
});
route('post', 'issues', async r => {
  const b = r.body;
  const x = await q('INSERT INTO ISSUE_RECORD(request_id,unit_id,staff_id) VALUES(?,?,?)', [b.request_id, b.unit_id, b.staff_id]);
  const [s] = await q('SELECT status FROM BLOOD_REQUEST WHERE request_id=?', [b.request_id]); return { issue_id: x.insertId, request_status: s.status }
});

app.listen(process.env.PORT || 3000, () => console.log('BBMS running at http://localhost:' + (process.env.PORT || 3000)));
