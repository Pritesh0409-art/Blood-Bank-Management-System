HEAD
# BBMS – run
1. Install Node 18+ and MySQL 8.0.16+.
2. `cd bbms && npm install`
3. `npm run setup`   (loads db/bbms.sql → blood_bank_db; set DB_USER / DB_PASSWORD env vars if not root with empty password)
4. `npm start`  → open http://localhost:3000
Flow: index.html (login) → staff.html ⇄ intake.html (staff) | hospital.html (hospital) | donor card on index.html (donor)

# Blood-Bank-Management-System
This is a part of our mini project for the DBMS subject. We chose this as our project because we feel that, this could be useful in someway in improving our community
61fd422331fda9e3bb0fbf181c8e81997cc77d19
