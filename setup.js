// Loads db/bbms.sql into MySQL (handles DELIMITER blocks for triggers). Run: npm run setup
const mysql=require('mysql2/promise'),fs=require('fs');
(async()=>{
 
const c = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'blood_bank_db'
});

 let delim=';',buf='',n=0;
 for(const line of fs.readFileSync(__dirname+'/db/bbms.sql','utf8').split(/\r?\n/)){
  const m=line.match(/^DELIMITER\s+(\S+)/i); if(m){delim=m[1];continue;}
  buf+=line+'\n';
  if(line.trimEnd().endsWith(delim)){
   const sql=buf.trim().slice(0,-delim.length).trim(); buf='';
   if(sql.replace(/--.*$/gm,'').trim()){await c.query(sql);n++;}
  }
 }
 try{await c.query('SET GLOBAL event_scheduler=ON')}catch(e){console.log('Note: could not enable event scheduler (needs SUPER).')}
 console.log('Database blood_bank_db ready ('+n+' statements).');await c.end();
})().catch(e=>{console.error('Setup failed:',e.sqlMessage||e.message);process.exit(1)});
