// Loads db/bbms.sql into MySQL (handles DELIMITER blocks for triggers).
// Run: npm run setup

const mysql = require('mysql2/promise');
const fs = require('fs');

(async () => {

    const c = await mysql.createConnection({
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || ''
    });

    let delim = ';';
    let buf = '';
    let n = 0;

    const lines = fs.readFileSync(__dirname + '/db/bbms.sql', 'utf8')
        .split(/\r?\n/);

    for (const line of lines) {

        const m = line.match(/^DELIMITER\s+(\S+)/i);

        if (m) {
            delim = m[1];
            continue;
        }

        buf += line + '\n';

        // Remove a comment at the end of the line
        const lineWithoutComment = line.replace(/\s+--.*$/, '').trimEnd();

        if (lineWithoutComment.endsWith(delim)) {

            const sql = buf.trim().slice(0, -delim.length).trim();
            buf = '';

            if (sql.replace(/--.*$/gm, '').trim()) {
                await c.query(sql);
                n++;
            }
        }
    }

    try {
        await c.query('SET GLOBAL event_scheduler=ON');
    } catch (e) {
        console.log('Note: could not enable event scheduler (needs SUPER).');
    }

    console.log('Database blood_bank_db ready (' + n + ' statements).');

    await c.end();

})().catch(e => {
    console.error('Setup failed:', e.sqlMessage || e.message);
    process.exit(1);
});