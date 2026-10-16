const express = require('express');
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'blood_bank_db',
    dateStrings: true,
    ssl: process.env.DB_HOST
        ? { rejectUnauthorized: false }
        : undefined
});

const app = express();

app.use(express.json());
app.use(express.static(__dirname + '/public'));

const q = async (sql, params = []) =>
    (await pool.query(sql, params))[0];

const bad = message => ({ user: message });

const route = (method, path, handler) => {
    app[method]('/api/' + path, async (req, res) => {
        try {
            res.json(await handler(req));
        } catch (e) {
            const clientError =
                [1062, 3819, 1452, 1048, 1406, 1265].includes(e.errno) ||
                e.sqlState === '45000' ||
                e.user;

            res.status(clientError ? 400 : 500).json({
                error: e.user || e.sqlMessage || e.message
            });
        }
    });
};

const ISSUED =
    '(SELECT COUNT(*) FROM ISSUE_RECORD ir WHERE ir.request_id = br.request_id)';

route('get', 'public', async () => ({
    stock: await q(`
        SELECT bg.blood_group,
               COUNT(bu.unit_id) AS available_units
        FROM (
            SELECT DISTINCT donor_group AS blood_group
            FROM COMPATIBILITY
        ) bg
        LEFT JOIN BLOOD_UNIT bu
            ON bu.blood_group = bg.blood_group
            AND bu.status = 'Available'
            AND bu.expiry_date >= CURDATE()
        GROUP BY bg.blood_group
        ORDER BY bg.blood_group
    `),

    camps: await q(`
        SELECT c.*,
               COUNT(CASE WHEN dn.screening_result = 'Fit'
                          THEN 1 END) AS collected
        FROM CAMP c
        LEFT JOIN DONATION dn ON dn.camp_id = c.camp_id
        GROUP BY c.camp_id
        ORDER BY c.camp_date
    `),

    hospitals: await q(
        'SELECT hospital_id, name FROM HOSPITAL ORDER BY name'
    ),

    staff: await q(
        'SELECT staff_id, name, role FROM STAFF ORDER BY staff_id'
    )
}));

route('post', 'login', async req => {
    const { role, id } = req.body;

    if (!id) {
        throw bad('Enter an identifier');
    }

    const tables = {
        staff: ['STAFF', 'staff_id'],
        hospital: ['HOSPITAL', 'hospital_id'],
        donor: ['DONOR', 'donor_id']
    };

    const table = tables[role];

    if (!table) {
        throw bad('Invalid role');
    }

    const rows = await q(
        `SELECT * FROM ${table[0]}
         WHERE ${table[1]} = ? OR contact_no = ?`,
        [id, id]
    );

    if (!rows.length) {
        throw bad('No matching ' + role + ' record in the database');
    }

    return rows[0];
});

route('get', 'donor/:id', async req => {
    const [donor] = await q(`
        SELECT *,
               DATEDIFF(CURDATE(), last_donation_date) AS days_since,
               (
                   last_donation_date IS NULL OR
                   DATEDIFF(CURDATE(), last_donation_date) >=
                   IF(gender = 'Female', 120, 90)
               ) AS eligible
        FROM DONOR
        WHERE donor_id = ?
    `, [req.params.id]);

    return {
        donor,
        history: await q(`
            SELECT *
            FROM donor_history_view
            WHERE donor_id = ?
            ORDER BY donation_date
        `, [req.params.id])
    };
});

route('get', 'staff-dash', async () => {
    const [kpi] = await q(`
        SELECT
            (SELECT COUNT(*) FROM available_stock_view) AS available,
            (SELECT COUNT(*) FROM pending_requests_view) AS pending,
            (SELECT COUNT(*) FROM DONOR) AS donors,
            (
                SELECT COUNT(*)
                FROM DONOR
                WHERE weight >= 45
                  AND (
                      last_donation_date IS NULL OR
                      DATEDIFF(CURDATE(), last_donation_date) >=
                      IF(gender = 'Female', 120, 90)
                  )
            ) AS eligible,
            (
                SELECT COUNT(*)
                FROM BLOOD_UNIT
                WHERE status = 'Available'
                  AND DATEDIFF(expiry_date, CURDATE()) BETWEEN 0 AND 10
            ) AS near_expiry
    `);

    return {
        kpi,

        requests: await q(`
            SELECT br.request_id,
                   h.name AS hospital_name,
                   br.blood_group_needed,
                   br.component_type,
                   br.quantity_required,
                   br.urgency_level,
                   br.request_date,
                   br.status,
                   ${ISSUED} AS issued
            FROM BLOOD_REQUEST br
            JOIN HOSPITAL h ON h.hospital_id = br.hospital_id
            WHERE br.status IN ('Pending', 'Partially Fulfilled')
            ORDER BY FIELD(br.urgency_level, 'Emergency', 'Routine'),
                     br.request_date
        `),

        units: await q(`
            SELECT bu.unit_id,
                   bu.blood_group,
                   bu.component_type,
                   bu.collection_date,
                   bu.expiry_date,
                   bu.status,
                   DATEDIFF(bu.expiry_date, CURDATE()) AS days_left,
                   d.name AS donor_name
            FROM BLOOD_UNIT bu
            JOIN DONATION dn ON dn.donation_id = bu.donation_id
            JOIN DONOR d ON d.donor_id = dn.donor_id
            ORDER BY bu.unit_id
        `),

        issues: await issues()
    };
});

const issues = hospitalId => q(`
    SELECT ir.issue_id,
           ir.request_id,
           d.name AS donor_name,
           bu.unit_id,
           bu.blood_group,
           bu.component_type,
           h.name AS hospital_name,
           s.name AS issued_by,
           ir.issue_date
    FROM ISSUE_RECORD ir
    JOIN BLOOD_UNIT bu ON ir.unit_id = bu.unit_id
    JOIN DONATION dn ON bu.donation_id = dn.donation_id
    JOIN DONOR d ON dn.donor_id = d.donor_id
    JOIN BLOOD_REQUEST br ON ir.request_id = br.request_id
    JOIN HOSPITAL h ON br.hospital_id = h.hospital_id
    JOIN STAFF s ON ir.staff_id = s.staff_id
    ${hospitalId ? 'WHERE h.hospital_id = ?' : ''}
    ORDER BY ir.issue_date DESC, ir.issue_id DESC
`, hospitalId ? [hospitalId] : []);

route('get', 'request/:id/units', req => q(`
    SELECT v.*
    FROM available_stock_view v
    JOIN BLOOD_REQUEST br
        ON br.request_id = ?
        AND v.component_type = br.component_type
    JOIN COMPATIBILITY c
        ON c.recipient_group = br.blood_group_needed
        AND c.donor_group = v.blood_group
    ORDER BY v.expiry_date
`, [req.params.id]));

route('get', 'compat', async req => {
    const { group, component } = req.query;

    const groups = await q(`
        SELECT donor_group
        FROM COMPATIBILITY
        WHERE recipient_group = ?
        ORDER BY donor_group
    `, [group]);

    const [result] = await q(`
        SELECT COUNT(*) AS n
        FROM available_stock_view
        WHERE component_type = ?
          AND blood_group IN (
              SELECT donor_group
              FROM COMPATIBILITY
              WHERE recipient_group = ?
          )
    `, [component, group]);

    return {
        groups: groups.map(row => row.donor_group),
        stock: result.n
    };
});

route('get', 'hospital/:id', async req => ({
    requests: await q(`
        SELECT br.*, ${ISSUED} AS issued
        FROM BLOOD_REQUEST br
        WHERE hospital_id = ?
        ORDER BY request_id DESC
    `, [req.params.id]),

    issues: await issues(req.params.id)
}));

route('get', 'donors', () => q(`
    SELECT d.*,
           (
               d.weight >= 45 AND
               (
                   d.last_donation_date IS NULL OR
                   DATEDIFF(CURDATE(), d.last_donation_date) >=
                   IF(d.gender = 'Female', 120, 90)
               )
           ) AS eligible
    FROM DONOR d
    ORDER BY donor_id DESC
`));

route('post', 'donors', async req => {
    const b = req.body;

    const result = await q(`
        INSERT INTO DONOR
            (name, age, weight, gender, blood_group, contact_no, address)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [
        b.name,
        b.age,
        b.weight,
        b.gender,
        b.blood_group,
        b.contact_no,
        b.address || null
    ]);

    return { donor_id: result.insertId };
});

route('post', 'donations', async req => {
    const b = req.body;

    const result = await q(`
        INSERT INTO DONATION
            (donor_id, camp_id, quantity_ml, screening_result)
        VALUES (?, ?, ?, ?)
    `, [
        b.donor_id,
        b.camp_id || null,
        b.quantity_ml,
        b.screening_result
    ]);

    const units = await q(
        'SELECT unit_id FROM BLOOD_UNIT WHERE donation_id = ?',
        [result.insertId]
    );

    return {
        donation_id: result.insertId,
        unit_id: units[0]?.unit_id || null
    };
});

route('post', 'requests', async req => {
    const b = req.body;

    const result = await q(`
        INSERT INTO BLOOD_REQUEST
            (hospital_id, blood_group_needed, component_type,
             quantity_required, urgency_level)
        VALUES (?, ?, ?, ?, ?)
    `, [
        b.hospital_id,
        b.blood_group_needed,
        b.component_type,
        b.quantity_required,
        b.urgency_level
    ]);

    return { request_id: result.insertId };
});

route('post', 'issues', async req => {
    const b = req.body;

    const result = await q(`
        INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id)
        VALUES (?, ?, ?)
    `, [
        b.request_id,
        b.unit_id,
        b.staff_id
    ]);

    const [request] = await q(
        'SELECT status FROM BLOOD_REQUEST WHERE request_id = ?',
        [b.request_id]
    );

    return {
        issue_id: result.insertId,
        request_status: request?.status
    };
});

app.listen(process.env.PORT || 3000, () => {
    console.log(
        'BBMS running on port ' + (process.env.PORT || 3000)
    );
});
