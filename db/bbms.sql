-- =====================================================================
-- BLOOD BANK MANAGEMENT SYSTEM  (corrected version)
-- Requires MySQL 8.0.16+ (CHECK constraints, DEFAULT (CURRENT_DATE))
-- =====================================================================

DROP DATABASE IF EXISTS blood_bank_db;
CREATE DATABASE blood_bank_db;
USE blood_bank_db;

-- =====================================================================
-- SECTION 1: TABLE CREATION (DDL)
-- =====================================================================

-- 1.1 DONOR
CREATE TABLE DONOR (
    donor_id            INT AUTO_INCREMENT PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    age                 INT NOT NULL,
    weight              INT NOT NULL,
    gender              VARCHAR(10) NOT NULL,
    blood_group         VARCHAR(3)  NOT NULL,
    contact_no          VARCHAR(15) NOT NULL UNIQUE,
    address             VARCHAR(200),
    last_donation_date  DATE,
    CONSTRAINT chk_donor_age    CHECK (age BETWEEN 18 AND 65),
    CONSTRAINT chk_donor_weight CHECK (weight > 0),
    CONSTRAINT chk_donor_bg     CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_donor_gender CHECK (gender IN ('Male','Female','Other'))
);

-- 1.2 CAMP
CREATE TABLE CAMP (
    camp_id       INT AUTO_INCREMENT PRIMARY KEY,
    location      VARCHAR(200) NOT NULL,
    camp_date     DATE NOT NULL,
    organizer     VARCHAR(100),
    target_units  INT,
    CONSTRAINT chk_camp_target CHECK (target_units > 0)
);

-- 1.3 DONATION
CREATE TABLE DONATION (
    donation_id       INT AUTO_INCREMENT PRIMARY KEY,
    donor_id          INT NOT NULL,
    camp_id           INT,
    donation_date     DATE NOT NULL DEFAULT (CURRENT_DATE),
    quantity_ml       INT NOT NULL,
    screening_result  VARCHAR(10) NOT NULL,
    CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id) REFERENCES DONOR(donor_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_donation_camp FOREIGN KEY (camp_id) REFERENCES CAMP(camp_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_donation_qty CHECK (quantity_ml > 0),
    CONSTRAINT chk_screening_result CHECK (screening_result IN ('Fit','Unfit','Pending'))
);

-- 1.4 BLOOD_UNIT
CREATE TABLE BLOOD_UNIT (
    unit_id          INT AUTO_INCREMENT PRIMARY KEY,
    donation_id      INT NOT NULL,
    blood_group      VARCHAR(3) NOT NULL,
    component_type   VARCHAR(20) NOT NULL,
    collection_date  DATE NOT NULL,
    expiry_date      DATE NOT NULL,
    status           VARCHAR(15) NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_unit_donation FOREIGN KEY (donation_id) REFERENCES DONATION(donation_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_unit_bg CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_unit_component CHECK (component_type IN ('Whole Blood','Plasma','Platelets','RBC')),
    CONSTRAINT chk_unit_status CHECK (status IN ('Available','Reserved','Issued','Expired','Discarded')),
    CONSTRAINT chk_unit_dates CHECK (expiry_date >= collection_date)
);

-- 1.5 HOSPITAL
CREATE TABLE HOSPITAL (
    hospital_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    contact_no     VARCHAR(15) NOT NULL,
    address        VARCHAR(200)
);

-- 1.6 BLOOD_REQUEST
CREATE TABLE BLOOD_REQUEST (
    request_id           INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id          INT NOT NULL,
    blood_group_needed   VARCHAR(3) NOT NULL,
    component_type       VARCHAR(20) NOT NULL,
    quantity_required    INT NOT NULL,
    urgency_level        VARCHAR(10) NOT NULL,
    request_date         DATE NOT NULL DEFAULT (CURRENT_DATE),
    status               VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_request_hospital FOREIGN KEY (hospital_id) REFERENCES HOSPITAL(hospital_id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_request_bg CHECK (blood_group_needed IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_request_component CHECK (component_type IN ('Whole Blood','Plasma','Platelets','RBC')),
    CONSTRAINT chk_request_qty CHECK (quantity_required > 0),
    CONSTRAINT chk_request_urgency CHECK (urgency_level IN ('Emergency','Routine')),
    CONSTRAINT chk_request_status CHECK (status IN ('Pending','Partially Fulfilled','Fulfilled','Rejected'))
);

-- 1.7 STAFF
CREATE TABLE STAFF (
    staff_id    INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(30) NOT NULL,
    contact_no  VARCHAR(15)
);

-- 1.8 ISSUE_RECORD
CREATE TABLE ISSUE_RECORD (
    issue_id     INT AUTO_INCREMENT PRIMARY KEY,
    request_id   INT NOT NULL,
    unit_id      INT NOT NULL UNIQUE,   -- a unit can be issued only once
    staff_id     INT NOT NULL,
    issue_date   DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_issue_request FOREIGN KEY (request_id) REFERENCES BLOOD_REQUEST(request_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_issue_unit FOREIGN KEY (unit_id) REFERENCES BLOOD_UNIT(unit_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_issue_staff FOREIGN KEY (staff_id) REFERENCES STAFF(staff_id)
        ON UPDATE CASCADE
);

-- 1.9 COMPATIBILITY (lookup table for blood-group matching)
CREATE TABLE COMPATIBILITY (
    donor_group      VARCHAR(3) NOT NULL,
    recipient_group  VARCHAR(3) NOT NULL,
    PRIMARY KEY (donor_group, recipient_group)
);

-- =====================================================================
-- SECTION 2: SAMPLE DATA (DML)
-- NOTE: triggers are created in Section 5, AFTER this data is loaded,
--       so the inserts below are not affected by them.
-- =====================================================================

-- 2.1 Compatibility rules (who can donate to whom)
INSERT INTO COMPATIBILITY (donor_group, recipient_group) VALUES
('O-','O-'),('O-','O+'),('O-','A-'),('O-','A+'),('O-','B-'),('O-','B+'),('O-','AB-'),('O-','AB+'),
('O+','O+'),('O+','A+'),('O+','B+'),('O+','AB+'),
('A-','A-'),('A-','A+'),('A-','AB-'),('A-','AB+'),
('A+','A+'),('A+','AB+'),
('B-','B-'),('B-','B+'),('B-','AB-'),('B-','AB+'),
('B+','B+'),('B+','AB+'),
('AB-','AB-'),('AB-','AB+'),
('AB+','AB+');

-- 2.2 Staff
INSERT INTO STAFF (name, role, contact_no) VALUES
('Ramesh Iyer',   'Admin',      '9820011122'),
('Sunita Nair',   'Technician', '9820011123'),
('Faisal Khan',   'Doctor',     '9820011124'),
('Priya Menon',   'Technician', '9820011125');

-- 2.3 Camps
INSERT INTO CAMP (location, camp_date, organizer, target_units) VALUES
('Andheri Community Hall',    '2026-08-01', 'Lions Club Mumbai',      50),
('IIT Bombay Campus',         '2026-08-15', 'IIT-B Student Council',  80),
('Thane Municipal Ground',    '2026-09-05', 'Rotary Club Thane',      60);

-- 2.4 Donors (last_donation_date is filled in automatically in 2.5a,
--     so it always agrees with the DONATION table)
INSERT INTO DONOR (name, age, weight, gender, blood_group, contact_no, address) VALUES
('Aarav Sharma',    28, 72, 'Male',   'O+',  '9900000001', 'Andheri, Mumbai'),
('Diya Patel',      34, 61, 'Female', 'A+',  '9900000002', 'Bandra, Mumbai'),
('Rohan Gupta',     41, 78, 'Male',   'B+',  '9900000003', 'Powai, Mumbai'),
('Sneha Reddy',     25, 55, 'Female', 'O-',  '9900000004', 'Dadar, Mumbai'),
('Kabir Verma',     30, 82, 'Male',   'AB+', '9900000005', 'Kurla, Mumbai'),
('Ananya Iyer',     22, 52, 'Female', 'A-',  '9900000006', 'Chembur, Mumbai'),
('Vivaan Joshi',    45, 74, 'Male',   'B-',  '9900000007', 'Thane West'),
('Ishita Kapoor',   29, 58, 'Female', 'AB-', '9900000008', 'Vashi, Navi Mumbai'),
('Aditya Rao',      33, 69, 'Male',   'O+',  '9900000009', 'Ghatkopar, Mumbai'),
('Meera Nair',      27, 63, 'Female', 'A+',  '9900000010', 'Malad, Mumbai'),
('Karan Malhotra',  38, 76, 'Male',   'O-',  '9900000011', 'Borivali, Mumbai'),
('Priyanka Das',    31, 59, 'Female', 'B+',  '9900000012', 'Mulund, Mumbai'),
('Arjun Singh',     26, 81, 'Male',   'AB+', '9900000013', 'Wadala, Mumbai'),
('Neha Choudhary',  36, 64, 'Female', 'O+',  '9900000014', 'Sion, Mumbai'),
('Devansh Mehta',   24, 70, 'Male',   'A-',  '9900000015', 'Colaba, Mumbai'),
('Riya Desai',      39, 57, 'Female', 'B-',  '9900000016', 'Worli, Mumbai'),
('Yash Kulkarni',   32, 73, 'Male',   'O+',  '9900000017', 'Dombivli'),
('Tanvi Bhatt',     23, 53, 'Female', 'AB-', '9900000018', 'Kalyan'),
('Siddharth Rao',   43, 79, 'Male',   'A+',  '9900000019', 'Panvel'),
('Kavya Menon',     28, 56, 'Female', 'O-',  '9900000020', 'Navi Mumbai'),
('Rahul Trivedi',   35, 75, 'Male',   'B+',  '9900000021', 'Airoli'),
('Simran Kaur',     30, 62, 'Female', 'AB+', '9900000022', 'Ghansoli');

-- 2.5 Donations
INSERT INTO DONATION (donor_id, camp_id, donation_date, quantity_ml, screening_result) VALUES
(1,  1,    '2026-08-01', 450, 'Fit'),
(2,  NULL, '2026-08-03', 450, 'Fit'),
(3,  2,    '2026-08-15', 450, 'Fit'),
(4,  NULL, '2026-08-05', 450, 'Fit'),
(5,  2,    '2026-08-15', 450, 'Fit'),
(6,  NULL, '2026-08-10', 450, 'Fit'),
(7,  3,    '2026-09-05', 450, 'Unfit'),
(8,  NULL, '2026-08-20', 450, 'Fit'),
(9,  1,    '2026-08-01', 450, 'Fit'),
(10, NULL, '2026-08-22', 450, 'Fit'),
(11, 3,    '2026-09-05', 450, 'Fit'),
(12, NULL, '2026-08-25', 450, 'Fit'),
(13, NULL, '2026-08-27', 450, 'Fit'),
(14, 2,    '2026-08-15', 450, 'Fit'),
(15, NULL, '2026-09-01', 450, 'Fit'),
(16, NULL, '2026-09-02', 450, 'Fit'),
(17, 3,    '2026-09-05', 450, 'Fit'),
(18, NULL, '2026-09-08', 450, 'Fit'),
(19, NULL, '2026-09-10', 450, 'Fit'),
(20, 1,    '2026-08-01', 450, 'Fit'),
(21, NULL, '2026-09-12', 450, 'Fit'),
(22, NULL, '2026-09-14', 450, 'Fit');

-- 2.5a Sync each donor's last_donation_date with their latest 'Fit' donation
UPDATE DONOR d
JOIN (SELECT donor_id, MAX(donation_date) AS last_date
      FROM DONATION
      WHERE screening_result = 'Fit'
      GROUP BY donor_id) x ON x.donor_id = d.donor_id
SET d.last_donation_date = x.last_date;

-- 2.6 Blood Units — one per 'Fit' donation (the trigger in 5.2 does this
--     automatically for NEW donations).
-- Expiry rule: Whole Blood/RBC = +42 days, Platelets = +5 days, Plasma = +365 days.
-- Because donation 7 is 'Unfit' (no unit), unit_id = donation_id for 1-6
-- and unit_id = donation_id - 1 from donation 8 onwards.
INSERT INTO BLOOD_UNIT (donation_id, blood_group, component_type, collection_date, expiry_date, status) VALUES
(1,  'O+',  'Whole Blood', '2026-08-01', '2026-09-12', 'Available'),  -- unit 1
(2,  'A+',  'Whole Blood', '2026-08-03', '2026-09-14', 'Available'),  -- unit 2
(3,  'B+',  'Whole Blood', '2026-08-15', '2026-09-26', 'Available'),  -- unit 3
(4,  'O-',  'Whole Blood', '2026-08-05', '2026-09-16', 'Available'),  -- unit 4
(5,  'AB+', 'Plasma',      '2026-08-15', '2027-08-15', 'Available'),  -- unit 5
(6,  'A-',  'Whole Blood', '2026-08-10', '2026-09-21', 'Available'),  -- unit 6
(8,  'AB-', 'Platelets',   '2026-08-20', '2026-08-25', 'Expired'),    -- unit 7
(9,  'O+',  'Whole Blood', '2026-08-01', '2026-09-12', 'Issued'),     -- unit 8
(10, 'A+',  'RBC',         '2026-08-22', '2026-10-03', 'Available'),  -- unit 9
(11, 'O-',  'Whole Blood', '2026-09-05', '2026-10-17', 'Available'),  -- unit 10
(12, 'B+',  'Plasma',      '2026-08-25', '2027-08-25', 'Available'),  -- unit 11
(13, 'AB+', 'Whole Blood', '2026-08-27', '2026-10-08', 'Available'),  -- unit 12
(14, 'O+',  'Platelets',   '2026-08-15', '2026-08-20', 'Discarded'),  -- unit 13
(15, 'A-',  'Whole Blood', '2026-09-01', '2026-10-13', 'Available'),  -- unit 14
(16, 'B-',  'Whole Blood', '2026-09-02', '2026-10-14', 'Available'),  -- unit 15
(17, 'O+',  'RBC',         '2026-09-05', '2026-10-17', 'Reserved'),   -- unit 16
(18, 'AB-', 'Whole Blood', '2026-09-08', '2026-10-20', 'Available'),  -- unit 17
(19, 'A+',  'Whole Blood', '2026-09-10', '2026-10-22', 'Available'),  -- unit 18
(20, 'O-',  'Whole Blood', '2026-08-01', '2026-09-12', 'Available'),  -- unit 19
(21, 'B+',  'Whole Blood', '2026-09-12', '2026-10-24', 'Available'),  -- unit 20
(22, 'AB+', 'Whole Blood', '2026-09-14', '2026-10-26', 'Available');  -- unit 21

-- 2.7 Hospitals
INSERT INTO HOSPITAL (name, contact_no, address) VALUES
('City Care Hospital',          '02226001111', 'Andheri East, Mumbai'),
('Sion General Hospital',       '02224021234', 'Sion, Mumbai'),
('Lifeline Multispeciality',    '02228765432', 'Powai, Mumbai'),
('Thane Civil Hospital',        '02225432198', 'Thane West'),
('Apex Medical Centre',         '02226789900', 'Vashi, Navi Mumbai'),
('Kokilaben Trust Hospital',    '02230012345', 'Andheri West, Mumbai'),
('Rajawadi Municipal Hospital', '02221345678', 'Ghatkopar, Mumbai');

-- 2.8 Blood Requests
INSERT INTO BLOOD_REQUEST (hospital_id, blood_group_needed, component_type, quantity_required, urgency_level, request_date, status) VALUES
(1, 'O+',  'Whole Blood', 2, 'Emergency', '2026-09-12', 'Pending'),
(2, 'O-',  'Whole Blood', 1, 'Emergency', '2026-09-13', 'Pending'),
(3, 'A+',  'Whole Blood', 3, 'Routine',   '2026-09-14', 'Pending'),
(4, 'B+',  'Plasma',      1, 'Routine',   '2026-09-15', 'Pending'),
(5, 'AB+', 'Whole Blood', 2, 'Emergency', '2026-09-16', 'Pending'),
(1, 'A-',  'Whole Blood', 1, 'Routine',   '2026-09-17', 'Pending'),
(6, 'O+',  'RBC',         1, 'Emergency', '2026-09-18', 'Pending'),
(7, 'AB-', 'Whole Blood', 1, 'Routine',   '2026-09-19', 'Pending');

-- 2.9 Issue Records (each unit matches its request's group and component)
INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id, issue_date) VALUES
(1, 8,  2, '2026-09-12'),   -- unit 8  = O+ Whole Blood  -> request 1 (O+ Whole Blood, needs 2)
(3, 2,  3, '2026-09-14'),   -- unit 2  = A+ Whole Blood  -> request 3 (A+ Whole Blood, needs 3)
(3, 18, 3, '2026-09-14');   -- unit 18 = A+ Whole Blood  -> request 3

-- Reflect the issues (the trigger in 5.4 does this for future issues)
UPDATE BLOOD_UNIT SET status = 'Issued' WHERE unit_id IN (8, 2, 18);
UPDATE BLOOD_REQUEST SET status = 'Partially Fulfilled' WHERE request_id IN (1, 3);

-- 2.10 Mark units that have already passed their expiry date as 'Expired'
--      (the scheduled event in Section 6 keeps this up to date daily)
UPDATE BLOOD_UNIT
SET status = 'Expired'
WHERE unit_id > 0                      -- key column satisfies Workbench safe-update mode (Error 1175)
  AND status = 'Available'
  AND expiry_date < CURDATE();

-- =====================================================================
-- SECTION 3: CORE QUERIES
-- =====================================================================

-- 3.1  INNER JOIN
-- All currently available (non-expired) units with donor name and donation date.
SELECT bu.unit_id, bu.blood_group, bu.component_type, bu.status, bu.expiry_date,
       d.name AS donor_name, dn.donation_date
FROM BLOOD_UNIT bu
JOIN DONATION dn ON bu.donation_id = dn.donation_id
JOIN DONOR d     ON dn.donor_id    = d.donor_id
WHERE bu.status = 'Available'
  AND bu.expiry_date >= CURDATE();

-- 3.2  LEFT JOIN
-- All hospitals with their requests, including hospitals with none.
SELECT h.hospital_id, h.name, br.request_id, br.blood_group_needed, br.status
FROM HOSPITAL h
LEFT JOIN BLOOD_REQUEST br ON h.hospital_id = br.hospital_id
ORDER BY h.hospital_id;

-- 3.3  MULTI-TABLE JOIN
-- Full issue trail: donor -> donation -> unit -> issue -> request -> hospital -> staff.
SELECT ir.issue_id, d.name AS donor_name, dn.donation_date,
       bu.unit_id, bu.blood_group, bu.component_type,
       h.name AS hospital_name, s.name AS issued_by, ir.issue_date
FROM ISSUE_RECORD ir
JOIN BLOOD_UNIT bu    ON ir.unit_id     = bu.unit_id
JOIN DONATION dn      ON bu.donation_id = dn.donation_id
JOIN DONOR d          ON dn.donor_id    = d.donor_id
JOIN BLOOD_REQUEST br ON ir.request_id  = br.request_id
JOIN HOSPITAL h       ON br.hospital_id = h.hospital_id
JOIN STAFF s          ON ir.staff_id    = s.staff_id
ORDER BY ir.issue_date;

-- 3.4  AGGREGATE + GROUP BY
-- (a) Available (non-expired) units per blood group.
SELECT blood_group, COUNT(*) AS available_units
FROM BLOOD_UNIT
WHERE status = 'Available'
  AND expiry_date >= CURDATE()
GROUP BY blood_group
ORDER BY blood_group;

-- (b) Total quantity (ml) donated per month (Fit donations only).
SELECT DATE_FORMAT(donation_date, '%Y-%m') AS month, SUM(quantity_ml) AS total_ml
FROM DONATION
WHERE screening_result = 'Fit'
GROUP BY DATE_FORMAT(donation_date, '%Y-%m')
ORDER BY month;

-- 3.5  HAVING
-- Blood groups with fewer than 5 available units (critical shortage),
-- including groups with ZERO units.
SELECT bg.blood_group, COUNT(bu.unit_id) AS available_units
FROM (SELECT DISTINCT donor_group AS blood_group FROM COMPATIBILITY) bg
LEFT JOIN BLOOD_UNIT bu
       ON bu.blood_group = bg.blood_group
      AND bu.status = 'Available'
      AND bu.expiry_date >= CURDATE()
GROUP BY bg.blood_group
HAVING COUNT(bu.unit_id) < 5
ORDER BY available_units ASC, bg.blood_group;

-- 3.6  CORRELATED SUBQUERY / NOT EXISTS
-- Blood units that have never been issued.
SELECT bu.unit_id, bu.blood_group, bu.component_type, bu.status
FROM BLOOD_UNIT bu
WHERE NOT EXISTS (
    SELECT 1 FROM ISSUE_RECORD ir
    WHERE ir.unit_id = bu.unit_id
);

-- 3.7  Open requests whose REMAINING quantity exceeds current stock
--      (remaining = quantity_required - units already issued for that request)
SELECT t.request_id, t.hospital_name, t.blood_group_needed, t.component_type,
       t.quantity_required, t.units_issued,
       (t.quantity_required - t.units_issued) AS units_remaining,
       t.units_in_stock
FROM (
    SELECT br.request_id, h.name AS hospital_name,
           br.blood_group_needed, br.component_type, br.quantity_required,
           (SELECT COUNT(*) FROM ISSUE_RECORD ir
             WHERE ir.request_id = br.request_id) AS units_issued,
           (SELECT COUNT(*) FROM BLOOD_UNIT bu
             WHERE bu.blood_group    = br.blood_group_needed
               AND bu.component_type = br.component_type
               AND bu.status = 'Available'
               AND bu.expiry_date >= CURDATE()) AS units_in_stock
    FROM BLOOD_REQUEST br
    JOIN HOSPITAL h ON br.hospital_id = h.hospital_id
    WHERE br.status IN ('Pending','Partially Fulfilled')
) t
WHERE (t.quantity_required - t.units_issued) > t.units_in_stock;

-- 3.8  Units nearing expiry within 10 days (priority-issue candidates)
SELECT unit_id, blood_group, component_type, expiry_date,
       DATEDIFF(expiry_date, CURDATE()) AS days_to_expiry
FROM BLOOD_UNIT
WHERE status = 'Available'
  AND DATEDIFF(expiry_date, CURDATE()) BETWEEN 0 AND 10
ORDER BY expiry_date ASC;

-- 3.9  Most in-demand blood group(s) by total quantity requested (handles ties)
SELECT blood_group_needed, SUM(quantity_required) AS total_requested
FROM BLOOD_REQUEST
GROUP BY blood_group_needed
HAVING SUM(quantity_required) = (
    SELECT MAX(total)
    FROM (SELECT SUM(quantity_required) AS total
          FROM BLOOD_REQUEST
          GROUP BY blood_group_needed) x
)
ORDER BY blood_group_needed;

-- 3.10  Donors eligible to donate again today
--       (same rules as the trigger: 120 days for Female, 90 otherwise; weight >= 45 kg)
SELECT donor_id, name, gender, blood_group, last_donation_date,
       DATEDIFF(CURDATE(), last_donation_date) AS days_since_last
FROM DONOR
WHERE weight >= 45
  AND (last_donation_date IS NULL
       OR DATEDIFF(CURDATE(), last_donation_date) >=
          CASE gender WHEN 'Female' THEN 120 ELSE 90 END);

-- 3.11  Compatible donor blood groups for a given request (e.g. request_id = 5)
SELECT DISTINCT c.donor_group
FROM COMPATIBILITY c
JOIN BLOOD_REQUEST br ON c.recipient_group = br.blood_group_needed
WHERE br.request_id = 5;

-- 3.12  Wastage report — expired/discarded units grouped by blood group
SELECT blood_group, status, COUNT(*) AS unit_count
FROM BLOOD_UNIT
WHERE status IN ('Expired','Discarded')
GROUP BY blood_group, status
ORDER BY blood_group, status;

-- =====================================================================
-- SECTION 4: VIEWS
-- =====================================================================

-- 4.1 Currently available, non-expired stock
CREATE OR REPLACE VIEW available_stock_view AS
SELECT unit_id, blood_group, component_type, collection_date, expiry_date
FROM BLOOD_UNIT
WHERE status = 'Available'
  AND expiry_date >= CURDATE();
-- Usage: SELECT * FROM available_stock_view WHERE blood_group = 'O+';

-- 4.2 Donor donation history
CREATE OR REPLACE VIEW donor_history_view AS
SELECT d.donor_id, d.name, d.blood_group,
       dn.donation_id, dn.donation_date, dn.quantity_ml, dn.screening_result
FROM DONOR d
JOIN DONATION dn ON d.donor_id = dn.donor_id;
-- Usage: SELECT * FROM donor_history_view ORDER BY donor_id, donation_date;

-- 4.3 Pending / partially fulfilled requests with hospital details
CREATE OR REPLACE VIEW pending_requests_view AS
SELECT br.request_id, h.name AS hospital_name, br.blood_group_needed,
       br.component_type, br.quantity_required, br.urgency_level, br.request_date
FROM BLOOD_REQUEST br
JOIN HOSPITAL h ON br.hospital_id = h.hospital_id
WHERE br.status IN ('Pending','Partially Fulfilled');
-- Usage: SELECT * FROM pending_requests_view
--        ORDER BY FIELD(urgency_level,'Emergency','Routine'), request_date;

-- =====================================================================
-- SECTION 5: TRIGGERS
-- =====================================================================

DELIMITER //

-- 5.1 Donor eligibility: minimum gap between donations
CREATE TRIGGER trg_before_donation_insert
BEFORE INSERT ON DONATION
FOR EACH ROW
BEGIN
    DECLARE v_last_date DATE;
    DECLARE v_gender    VARCHAR(10);

    SELECT last_donation_date, gender
    INTO v_last_date, v_gender
    FROM DONOR
    WHERE donor_id = NEW.donor_id;

    IF v_last_date IS NOT NULL THEN
        IF v_gender = 'Female' AND DATEDIFF(NEW.donation_date, v_last_date) < 120 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Female donor is not yet eligible: must wait 120 days between donations';
        ELSEIF v_gender <> 'Female' AND DATEDIFF(NEW.donation_date, v_last_date) < 90 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Donor is not yet eligible: must wait 90 days between donations';
        END IF;
    END IF;
END//

-- 5.2 Minimum weight: 45 kg
CREATE TRIGGER trg_before_donation_weight_check
BEFORE INSERT ON DONATION
FOR EACH ROW
BEGIN
    DECLARE v_weight INT;

    SELECT weight INTO v_weight
    FROM DONOR
    WHERE donor_id = NEW.donor_id;

    IF v_weight < 45 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Donor is not eligible: minimum weight required is 45 kg';
    END IF;
END//

-- 5.3 After a 'Fit' donation is logged: update donor's last_donation_date
--     (never moves backwards) and auto-create the blood unit.
CREATE TRIGGER trg_after_donation_insert
AFTER INSERT ON DONATION
FOR EACH ROW
BEGIN
    DECLARE v_bg VARCHAR(3);

    IF NEW.screening_result = 'Fit' THEN
        UPDATE DONOR
        SET last_donation_date = IF(last_donation_date IS NULL
                                    OR last_donation_date < NEW.donation_date,
                                    NEW.donation_date, last_donation_date)
        WHERE donor_id = NEW.donor_id;

        SELECT blood_group INTO v_bg FROM DONOR WHERE donor_id = NEW.donor_id;

        INSERT INTO BLOOD_UNIT
            (donation_id, blood_group, component_type, collection_date, expiry_date, status)
        VALUES
            (NEW.donation_id, v_bg, 'Whole Blood', NEW.donation_date,
             DATE_ADD(NEW.donation_date, INTERVAL 42 DAY), 'Available');
    END IF;
END//

-- 5.4 If screening result changes from Pending/Unfit to 'Fit' later,
--     do the same as 5.3 (only once per donation).
CREATE TRIGGER trg_after_donation_update
AFTER UPDATE ON DONATION
FOR EACH ROW
BEGIN
    DECLARE v_bg VARCHAR(3);

    IF NEW.screening_result = 'Fit' AND OLD.screening_result <> 'Fit' THEN
        UPDATE DONOR
        SET last_donation_date = IF(last_donation_date IS NULL
                                    OR last_donation_date < NEW.donation_date,
                                    NEW.donation_date, last_donation_date)
        WHERE donor_id = NEW.donor_id;

        IF NOT EXISTS (SELECT 1 FROM BLOOD_UNIT WHERE donation_id = NEW.donation_id) THEN
            SELECT blood_group INTO v_bg FROM DONOR WHERE donor_id = NEW.donor_id;

            INSERT INTO BLOOD_UNIT
                (donation_id, blood_group, component_type, collection_date, expiry_date, status)
            VALUES
                (NEW.donation_id, v_bg, 'Whole Blood', NEW.donation_date,
                 DATE_ADD(NEW.donation_date, INTERVAL 42 DAY), 'Available');
        END IF;
    END IF;
END//

-- 5.5 Validate an issue: unit available, not expired, request still open,
--     component matches, blood group compatible, quantity not exceeded.
CREATE TRIGGER trg_before_issue_insert
BEFORE INSERT ON ISSUE_RECORD
FOR EACH ROW
BEGIN
    DECLARE v_status       VARCHAR(15);
    DECLARE v_expiry       DATE;
    DECLARE v_bg           VARCHAR(3);
    DECLARE v_comp         VARCHAR(20);
    DECLARE v_req_status   VARCHAR(20);
    DECLARE v_need_bg      VARCHAR(3);
    DECLARE v_need_comp    VARCHAR(20);
    DECLARE v_required     INT;
    DECLARE v_issued_count INT;

    SELECT status, expiry_date, blood_group, component_type
    INTO v_status, v_expiry, v_bg, v_comp
    FROM BLOOD_UNIT WHERE unit_id = NEW.unit_id;

    SELECT status, blood_group_needed, component_type, quantity_required
    INTO v_req_status, v_need_bg, v_need_comp, v_required
    FROM BLOOD_REQUEST WHERE request_id = NEW.request_id;

    IF v_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: blood unit is not Available';
    END IF;

    IF v_expiry < NEW.issue_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: blood unit has expired';
    END IF;

    IF v_req_status IN ('Fulfilled','Rejected') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: request is already closed (Fulfilled/Rejected)';
    END IF;

    IF v_comp <> v_need_comp THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: component type does not match the request';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM COMPATIBILITY
                   WHERE donor_group = v_bg AND recipient_group = v_need_bg) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: blood group is not compatible with the request';
    END IF;

    SELECT COUNT(*) INTO v_issued_count
    FROM ISSUE_RECORD WHERE request_id = NEW.request_id;

    IF v_issued_count >= v_required THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: requested quantity already issued';
    END IF;
END//

-- 5.6 After a unit is issued: mark it 'Issued' and refresh the request status
CREATE TRIGGER trg_after_issue_insert
AFTER INSERT ON ISSUE_RECORD
FOR EACH ROW
BEGIN
    DECLARE v_required     INT;
    DECLARE v_issued_count INT;

    UPDATE BLOOD_UNIT
    SET status = 'Issued'
    WHERE unit_id = NEW.unit_id;

    SELECT quantity_required INTO v_required
    FROM BLOOD_REQUEST WHERE request_id = NEW.request_id;

    SELECT COUNT(*) INTO v_issued_count
    FROM ISSUE_RECORD WHERE request_id = NEW.request_id;

    IF v_issued_count >= v_required THEN
        UPDATE BLOOD_REQUEST SET status = 'Fulfilled' WHERE request_id = NEW.request_id;
    ELSE
        UPDATE BLOOD_REQUEST SET status = 'Partially Fulfilled' WHERE request_id = NEW.request_id;
    END IF;
END//

DELIMITER ;

-- =====================================================================
-- SECTION 6: SCHEDULED EVENT (auto-expire units daily)
-- Needs the event scheduler:  SET GLOBAL event_scheduler = ON;
-- =====================================================================

DROP EVENT IF EXISTS ev_expire_units;

DELIMITER //

CREATE EVENT ev_expire_units
ON SCHEDULE EVERY 1 DAY
DO
    UPDATE BLOOD_UNIT
    SET status = 'Expired'
    WHERE status = 'Available' AND expiry_date < CURDATE();

//

DELIMITER ;

-- =====================================================================
-- SECTION 7: TRIGGER TESTS (run one at a time; the first four should
-- FAIL with the message shown)
-- =====================================================================

-- Too soon after last donation (donor 1 donated 2026-08-01):
-- INSERT INTO DONATION (donor_id, donation_date, quantity_ml, screening_result)
-- VALUES (1, '2026-09-20', 450, 'Fit');

-- Wrong component for the request (unit 10 is Whole Blood, request 4 needs Plasma):
-- INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id) VALUES (4, 10, 2);

-- Incompatible group (unit 15 is B- Whole Blood, request 2 needs O-):
-- INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id) VALUES (2, 15, 2);

-- Expired / unavailable unit (unit 1 is now 'Expired'):
-- INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id) VALUES (1, 1, 2);

-- Valid issue (unit 10 = O- Whole Blood, request 2 = O- Whole Blood):
-- INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id) VALUES (2, 10, 2);
-- SELECT status FROM BLOOD_REQUEST WHERE request_id = 2;   -- 'Fulfilled'

-- =====================================================================
-- END OF SCRIPT
-- =====================================================================