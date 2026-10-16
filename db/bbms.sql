-- =====================================================================
-- BLOOD BANK MANAGEMENT SYSTEM 
-- =====================================================================

CREATE DATABASE IF NOT EXISTS blood_bank_db;
USE blood_bank_db;

-- =====================================================================
-- SECTION 1: TABLE CREATION (DDL)
-- =====================================================================

-- 1.1 DONOR
CREATE TABLE DONOR (
    donor_id            INT AUTO_INCREMENT PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    age                 INT NOT NULL,
    weight 		INT NOT NULL,
    gender              VARCHAR(10) NOT NULL,
    blood_group         VARCHAR(3)  NOT NULL,
    contact_no          VARCHAR(15) NOT NULL UNIQUE,
    address             VARCHAR(200),
    last_donation_date  DATE,
    CONSTRAINT chk_donor_age CHECK (age BETWEEN 18 AND 65),
    CONSTRAINT chk_donor_bg CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
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
    CONSTRAINT chk_unit_status CHECK (status IN ('Available','Reserved','Issued','Expired','Discarded'))
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

-- 2.4 Donors (20+ donors, mixed blood groups)
INSERT INTO DONOR
(name, age, weight, gender, blood_group, contact_no, address, last_donation_date)
VALUES
('Aarav Sharma',    28, 72, 'Male',   'O+',  '9900000001', 'Andheri, Mumbai',    '2026-06-01'),
('Diya Patel',      34, 61, 'Female', 'A+',  '9900000002', 'Bandra, Mumbai',     '2026-05-20'),
('Rohan Gupta',     41, 78, 'Male',   'B+',  '9900000003', 'Powai, Mumbai',      NULL),
('Sneha Reddy',     25, 55, 'Female', 'O-',  '9900000004', 'Dadar, Mumbai',      '2026-07-10'),
('Kabir Verma',     30, 82, 'Male',   'AB+', '9900000005', 'Kurla, Mumbai',      NULL),
('Ananya Iyer',     22, 52, 'Female', 'A-',  '9900000006', 'Chembur, Mumbai',    '2026-06-25'),
('Vivaan Joshi',    45, 74, 'Male',   'B-',  '9900000007', 'Thane West',         NULL),
('Ishita Kapoor',   29, 58, 'Female', 'AB-', '9900000008', 'Vashi, Navi Mumbai', NULL),
('Aditya Rao',      33, 69, 'Male',   'O+',  '9900000009', 'Ghatkopar, Mumbai',  '2026-07-01'),
('Meera Nair',      27, 63, 'Female', 'A+',  '9900000010', 'Malad, Mumbai',      NULL),
('Karan Malhotra',  38, 76, 'Male',   'O-',  '9900000011', 'Borivali, Mumbai',   '2026-06-15'),
('Priyanka Das',    31, 59, 'Female', 'B+',  '9900000012', 'Mulund, Mumbai',     NULL),
('Arjun Singh',     26, 81, 'Male',   'AB+', '9900000013', 'Wadala, Mumbai',     NULL),
('Neha Choudhary',  36, 64, 'Female', 'O+',  '9900000014', 'Sion, Mumbai',       '2026-07-18'),
('Devansh Mehta',   24, 70, 'Male',   'A-',  '9900000015', 'Colaba, Mumbai',     NULL),
('Riya Desai',      39, 57, 'Female', 'B-',  '9900000016', 'Worli, Mumbai',      NULL),
('Yash Kulkarni',   32, 73, 'Male',   'O+',  '9900000017', 'Dombivli',           '2026-05-30'),
('Tanvi Bhatt',     23, 53, 'Female', 'AB-', '9900000018', 'Kalyan',             NULL),
('Siddharth Rao',   43, 79, 'Male',   'A+',  '9900000019', 'Panvel',             NULL),
('Kavya Menon',     28, 56, 'Female', 'O-',  '9900000020', 'Navi Mumbai',        '2026-06-28'),
('Rahul Trivedi',   35, 75, 'Male',   'B+',  '9900000021', 'Airoli',             NULL),
('Simran Kaur',     30, 62, 'Female', 'AB+', '9900000022', 'Ghansoli',           NULL);

-- 2.5 Donations (linking donors to donation events, some via camps)
INSERT INTO DONATION (donor_id, camp_id, donation_date, quantity_ml, screening_result) VALUES
(1,  1, '2026-08-01', 450, 'Fit'),
(2,  NULL, '2026-08-03', 450, 'Fit'),
(3,  2, '2026-08-15', 450, 'Fit'),
(4,  NULL, '2026-08-05', 450, 'Fit'),
(5,  2, '2026-08-15', 450, 'Fit'),
(6,  NULL, '2026-08-10', 450, 'Fit'),
(7,  3, '2026-09-05', 450, 'Unfit'),
(8,  NULL, '2026-08-20', 450, 'Fit'),
(9,  1, '2026-08-01', 450, 'Fit'),
(10, NULL, '2026-08-22', 450, 'Fit'),
(11, 3, '2026-09-05', 450, 'Fit'),
(12, NULL, '2026-08-25', 450, 'Fit'),
(13, NULL, '2026-08-27', 450, 'Fit'),
(14, 2, '2026-08-15', 450, 'Fit'),
(15, NULL, '2026-09-01', 450, 'Fit'),
(16, NULL, '2026-09-02', 450, 'Fit'),
(17, 3, '2026-09-05', 450, 'Fit'),
(18, NULL, '2026-09-08', 450, 'Fit'),
(19, NULL, '2026-09-10', 450, 'Fit'),
(20, 1, '2026-08-01', 450, 'Fit'),
(21, NULL, '2026-09-12', 450, 'Fit'),
(22, NULL, '2026-09-14', 450, 'Fit');

-- 2.6 Blood Units — generated from every "Fit" donation.
-- (In the real system, a trigger does this automatically; see Section 5.)
-- Expiry rule used here: Whole Blood/RBC = +42 days, Platelets = +5 days, Plasma = +365 days.
INSERT INTO BLOOD_UNIT (donation_id, blood_group, component_type, collection_date, expiry_date, status) VALUES
(1,  'O+',  'Whole Blood', '2026-08-01', '2026-09-12', 'Available'),
(2,  'A+',  'Whole Blood', '2026-08-03', '2026-09-14', 'Available'),
(3,  'B+',  'Whole Blood', '2026-08-15', '2026-09-26', 'Available'),
(4,  'O-',  'Whole Blood', '2026-08-05', '2026-09-16', 'Available'),
(5,  'AB+', 'Plasma',      '2026-08-15', '2027-08-15', 'Available'),
(6,  'A-',  'Whole Blood', '2026-08-10', '2026-09-21', 'Available'),
-- donation_id 7 skipped: screening_result was 'Unfit', no unit generated
(8,  'AB-', 'Platelets',   '2026-08-20', '2026-08-25', 'Expired'),
(9,  'O+',  'Whole Blood', '2026-08-01', '2026-09-12', 'Issued'),
(10, 'A+',  'RBC',         '2026-08-22', '2026-10-03', 'Available'),
(11, 'O-',  'Whole Blood', '2026-09-05', '2026-10-17', 'Available'),
(12, 'B+',  'Plasma',      '2026-08-25', '2027-08-25', 'Available'),
(13, 'AB+', 'Whole Blood', '2026-08-27', '2026-10-08', 'Available'),
(14, 'O+',  'Platelets',   '2026-08-15', '2026-08-20', 'Discarded'),
(15, 'A-',  'Whole Blood', '2026-09-01', '2026-10-13', 'Available'),
(16, 'B-',  'Whole Blood', '2026-09-02', '2026-10-14', 'Available'),
(17, 'O+',  'RBC',         '2026-09-05', '2026-10-17', 'Reserved'),
(18, 'AB-', 'Whole Blood', '2026-09-08', '2026-10-20', 'Available'),
(19, 'A+',  'Whole Blood', '2026-09-10', '2026-10-22', 'Available'),
(20, 'O-',  'Whole Blood', '2026-08-01', '2026-09-12', 'Available'),
(21, 'B+',  'Whole Blood', '2026-09-12', '2026-10-24', 'Available'),
(22, 'AB+', 'Whole Blood', '2026-09-14', '2026-10-26', 'Available');

-- 2.7 Hospitals
INSERT INTO HOSPITAL (name, contact_no, address) VALUES
('City Care Hospital',        '02226001111', 'Andheri East, Mumbai'),
('Sion General Hospital',     '02224021234', 'Sion, Mumbai'),
('Lifeline Multispeciality',  '02228765432', 'Powai, Mumbai'),
('Thane Civil Hospital',      '02225432198', 'Thane West'),
('Apex Medical Centre',       '02226789900', 'Vashi, Navi Mumbai'),
('Kokilaben Trust Hospital',  '02230012345', 'Andheri West, Mumbai'),
('Rajawadi Municipal Hospital','02221345678','Ghatkopar, Mumbai');

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

-- 2.9 Issue Records (some requests partially/fully fulfilled)
INSERT INTO ISSUE_RECORD (request_id, unit_id, staff_id, issue_date) VALUES
(1, 9, 2, '2026-09-12'),   -- 1 of 2 units issued against request 1 (O+ Whole Blood)
(3, 2, 3, '2026-09-14'),   -- 1 of 3 units issued against request 3 (A+ Whole Blood)
(3, 10, 3, '2026-09-14');  -- 2nd unit for request 3

-- Reflect these issues in BLOOD_UNIT status (would normally be done by a trigger)
UPDATE BLOOD_UNIT SET status = 'Issued' WHERE unit_id IN (9, 2, 10);

-- Reflect partial fulfilment in BLOOD_REQUEST status
UPDATE BLOOD_REQUEST SET status = 'Partially Fulfilled' WHERE request_id IN (1, 3);


-- =====================================================================
-- SECTION 3: CORE QUERIES
-- =====================================================================

-- 3.1  INNER JOIN
-- List all currently available blood units with donor name and donation date.
SELECT bu.unit_id, bu.blood_group, bu.component_type, bu.status,
       d.name AS donor_name, dn.donation_date
FROM BLOOD_UNIT bu
JOIN DONATION dn ON bu.donation_id = dn.donation_id
JOIN DONOR d      ON dn.donor_id   = d.donor_id
WHERE bu.status = 'Available';

-- 3.2  LEFT JOIN
-- List all hospitals with their requests, including hospitals with none.
SELECT h.hospital_id, h.name, br.request_id, br.blood_group_needed, br.status
FROM HOSPITAL h
LEFT JOIN BLOOD_REQUEST br ON h.hospital_id = br.hospital_id
ORDER BY h.hospital_id;

-- 3.3  MULTI-TABLE JOIN
-- Full issue trail: donor -> donation -> unit -> issue -> hospital.
SELECT ir.issue_id, d.name AS donor_name, dn.donation_date,
       bu.unit_id, bu.blood_group, bu.component_type,
       h.name AS hospital_name, s.name AS issued_by, ir.issue_date
FROM ISSUE_RECORD ir
JOIN BLOOD_UNIT bu     ON ir.unit_id = bu.unit_id
JOIN DONATION dn       ON bu.donation_id = dn.donation_id
JOIN DONOR d           ON dn.donor_id = d.donor_id
JOIN BLOOD_REQUEST br  ON ir.request_id = br.request_id
JOIN HOSPITAL h        ON br.hospital_id = h.hospital_id
JOIN STAFF s           ON ir.staff_id = s.staff_id
ORDER BY ir.issue_date;

-- 3.4  AGGREGATE + GROUP BY
-- Count of available units per blood group.
SELECT blood_group, COUNT(*) AS available_units
FROM BLOOD_UNIT
WHERE status = 'Available'
GROUP BY blood_group
ORDER BY blood_group;

-- Total quantity (ml) donated per month.
SELECT DATE_FORMAT(donation_date, '%Y-%m') AS month, SUM(quantity_ml) AS total_ml
FROM DONATION
WHERE screening_result = 'Fit'
GROUP BY DATE_FORMAT(donation_date, '%Y-%m')
ORDER BY month;

-- 3.5  HAVING
-- Blood groups with fewer than 5 available units (critical shortage).
SELECT blood_group, COUNT(*) AS available_units
FROM BLOOD_UNIT
WHERE status = 'Available'
GROUP BY blood_group
HAVING COUNT(*) < 5
ORDER BY available_units ASC;


-- 3.6  CORRELATED SUBQUERY / NOT EXISTS
-- Blood units that have never been issued.
SELECT bu.unit_id, bu.blood_group, bu.component_type, bu.status
FROM BLOOD_UNIT bu
WHERE NOT EXISTS (
    SELECT 1 FROM ISSUE_RECORD ir 
    WHERE ir.unit_id = bu.unit_id
);

-- 3.7  Hospitals whose total requested quantity exceeds currently available compatible stock
SELECT h.name, br.blood_group_needed, br.quantity_required,
       (SELECT COUNT(*) FROM BLOOD_UNIT bu
        WHERE bu.blood_group = br.blood_group_needed
          AND bu.component_type = br.component_type
          AND bu.status = 'Available') AS units_in_stock
FROM BLOOD_REQUEST br
JOIN HOSPITAL h ON br.hospital_id = h.hospital_id
HAVING br.quantity_required > units_in_stock;

-- 3.8  Units nearing expiry within 10 days (priority-issue candidates)
SELECT unit_id, blood_group, component_type, expiry_date,
       DATEDIFF(expiry_date, CURDATE()) AS days_to_expiry
FROM BLOOD_UNIT
WHERE status = 'Available'
  AND DATEDIFF(expiry_date, CURDATE()) BETWEEN 0 AND 10
ORDER BY expiry_date ASC;

-- 3.9  Most in-demand blood group (by total quantity requested)
SELECT blood_group_needed, SUM(quantity_required) AS total_requested
FROM BLOOD_REQUEST
GROUP BY blood_group_needed
ORDER BY total_requested DESC
LIMIT 1;

-- 3.10  Donor eligibility check — donors eligible to donate again today
SELECT donor_id, name, blood_group, last_donation_date,
       DATEDIFF(CURDATE(), last_donation_date) AS days_since_last
FROM DONOR
WHERE last_donation_date IS NULL
   OR DATEDIFF(CURDATE(), last_donation_date) >= 90;

-- 3.11  Compatible donor blood groups for a given hospital request (e.g. request_id = 5)
SELECT DISTINCT c.donor_group
FROM COMPATIBILITY c
JOIN BLOOD_REQUEST br ON c.recipient_group = br.blood_group_needed
WHERE br.request_id = 5;

-- 3.12  Wastage report — expired/discarded units grouped by blood group
SELECT blood_group, status, COUNT(*) AS unit_count
FROM BLOOD_UNIT
WHERE status IN ('Expired','Discarded')
GROUP BY blood_group, status
ORDER BY blood_group;


-- =====================================================================
-- SECTION 4: VIEWS
-- =====================================================================

-- 4.1 Only non-expired, currently available stock (hides status/expiry filtering logic)
CREATE OR REPLACE VIEW AVAILABLE_STOCK_VIEW AS
SELECT unit_id, blood_group, component_type, collection_date, expiry_date
FROM BLOOD_UNIT
WHERE status = 'Available'
  AND expiry_date >= CURDATE();

-- Usage:
-- SELECT * FROM AVAILABLE_STOCK_VIEW WHERE blood_group = 'O+';

-- 4.2 Donor donation history, readable format
CREATE OR REPLACE VIEW DONOR_HISTORY_VIEW AS
SELECT d.donor_id, d.name, d.blood_group,
       dn.donation_id, dn.donation_date, dn.quantity_ml, dn.screening_result
FROM DONOR d
JOIN DONATION dn ON d.donor_id = dn.donor_id
ORDER BY d.donor_id, dn.donation_date;

-- 4.3 Pending/unfulfilled requests with hospital details
CREATE OR REPLACE VIEW PENDING_REQUESTS_VIEW AS
SELECT br.request_id, h.name AS hospital_name, br.blood_group_needed,
       br.component_type, br.quantity_required, br.urgency_level, br.request_date
FROM BLOOD_REQUEST br
JOIN HOSPITAL h ON br.hospital_id = h.hospital_id
WHERE br.status IN ('Pending','Partially Fulfilled')
ORDER BY FIELD(br.urgency_level, 'Emergency','Routine'), br.request_date;


-- =====================================================================
-- SECTION 5: TRIGGERS
-- =====================================================================

DELIMITER //

-- 5.1 Enforce donor eligibility before a new donation is logged
CREATE TRIGGER trg_before_donation_insert
BEFORE INSERT ON DONATION
FOR EACH ROW
BEGIN
    DECLARE v_last_date DATE;
    DECLARE v_gender VARCHAR(10);

    SELECT last_donation_date, gender
    INTO v_last_date, v_gender
    FROM DONOR
    WHERE donor_id = NEW.donor_id;

    IF v_last_date IS NOT NULL THEN
        IF v_gender = 'Male'
           AND DATEDIFF(NEW.donation_date, v_last_date) < 90 THEN

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Male donor is not yet eligible: must wait 90 days between donations';

        ELSEIF v_gender = 'Female'
           AND DATEDIFF(NEW.donation_date, v_last_date) < 120 THEN

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Female donor is not yet eligible: must wait 120 days between donations';

        ELSEIF v_gender = 'Other'
           AND DATEDIFF(NEW.donation_date, v_last_date) < 90 THEN

            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Donor is not yet eligible: must wait 90 days between donations';
        END IF;
    END IF;
END//


-- 5.2 After a donation is logged, update the donor's last_donation_date
CREATE TRIGGER trg_after_donation_insert
AFTER INSERT ON DONATION
FOR EACH ROW
BEGIN
    IF NEW.screening_result = 'Fit' THEN
        UPDATE DONOR
        SET last_donation_date = NEW.donation_date
        WHERE donor_id = NEW.donor_id;
    END IF;
END//

-- 5.3 Block issuing a unit that is not Available or has expired
CREATE TRIGGER trg_before_issue_insert
BEFORE INSERT ON ISSUE_RECORD
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(15);
    DECLARE v_expiry DATE;

    SELECT status, expiry_date INTO v_status, v_expiry
    FROM BLOOD_UNIT WHERE unit_id = NEW.unit_id;

    IF v_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: blood unit is not Available';
    END IF;

    IF v_expiry < NEW.issue_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot issue: blood unit has expired';
    END IF;
END//

-- 5.4 After a unit is issued, mark it as 'Issued' and refresh the request's status
CREATE TRIGGER trg_after_issue_insert
AFTER INSERT ON ISSUE_RECORD
FOR EACH ROW
BEGIN
    DECLARE v_required INT;
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

-- 5.5 Prevent donation if the donor weighs less than 45 kg
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
            SET MESSAGE_TEXT =
            'Donor is not eligible: minimum weight required is 45 kg';
    END IF;
END//

DELIMITER ;

-- =====================================================================
-- END OF SCRIPT
-- =====================================================================
