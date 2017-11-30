/*Stephen Bothner
Ben Rongey
Fall 2017
 */

CREATE TABLE Person (
  per_id INT,
  name VARCHAR(50),
  email VARCHAR(50),
  gender CHAR(1),
  PRIMARY KEY(per_id)
);

CREATE TABLE Job (
  job_code INT,
  empl_mode CHAR(2),
  pay_rate INT,
  pay_type CHAR(1),
  comp_id INT,
  job_location VARCHAR(50),
  job_title VARCHAR(50),
  job_description VARCHAR(50),
  per_id INT,
  cate_code INT,
  PRIMARY KEY(job_code),
    FOREIGN KEY(cate_code) REFERENCES Job_cate,
    FOREIGN KEY(comp_id) REFERENCES Company,
    FOREIGN KEY (per_id) REFERENCES Person
);

CREATE TABLE Job_cate (
  cate_code INT,
  cate_title VARCHAR(50),
  cate_decription VARCHAR(50),
  pay_range_high INT,
  pay_range_low INT,
  parent_id INT,
  PRIMARY KEY (cate_code, parent_id),
  FOREIGN KEY (parent_id) REFERENCES Soc_link
);

CREATE TABLE Company (
  comp_id INT,
  website VARCHAR(50),
  name VARCHAR(50),
  PRIMARY KEY (comp_id)
);

CREATE TABLE Business_sector (
  comp_id INT,
  nacis_code INT,
  PRIMARY KEY (comp_id),
  FOREIGN KEY (nacis_code) REFERENCES Naics,
  FOREIGN KEY (comp_id) REFERENCES Company
);

CREATE TABLE Naics (
  nacis_code INT,
  nacis_description VARCHAR(50),
  PRIMARY KEY (nacis_code)
);

CREATE TABLE Soc_link (
  group_id INT,
  parent_id INT,
  PRIMARY KEY (group_id, parent_id),
    FOREIGN KEY (group_id) REFERENCES Soc
);

CREATE TABLE Work_history (
  per_id INT,
  job_code INT,
  date_start VARCHAR(10),
  date_end VARCHAR(10),
  PRIMARY KEY (per_id, job_code),
    FOREIGN KEY (per_id) REFERENCES Person,
    FOREIGN KEY (job_code) REFERENCES Job
);

CREATE TABLE Soc (
  group_id INT,
  detailed_occupation VARCHAR(50),
  soc_description VARCHAR(50),
  PRIMARY KEY (group_id)
);

CREATE TABLE KNOWLEDGE_SKILLS (
  ks_code INT,
  ks_title VARCHAR(50),
  ks_description VARCHAR(50),
  ks_level VARCHAR(25),
    PRIMARY KEY (ks_code)
);

CREATE TABLE HAS_SKILL (
  PER_ID INT,
  KS_CODE INT,
  PRIMARY KEY (PER_ID, KS_CODE),
    FOREIGN KEY (PER_ID) REFERENCES PERSON,
    FOREIGN KEY (KS_CODE) REFERENCES KNOWLEDGE_SKILLS
);

CREATE TABLE COURSE (
  C_CODE INT,
  C_TITLTE VARCHAR(50),
  C_LEVEL VARCHAR(25),
  C_DESCRIPTION VARCHAR(50),
  C_STATUS VARCHAR(25),
  C_PRICE INT,
  PRIMARY KEY (C_CODE)
);

CREATE TABLE PREREQ (
  C_CODE INT,
  PREREQ_CODE INT,
  PRIMARY KEY (C_CODE, PREREQ_CODE),
    FOREIGN KEY (C_CODE) REFERENCES COURSE
);

CREATE TABLE SECTION (
  SEC_NUM INT,
  SEC_YEAR INT,
  SEC_OFFERED_BY VARCHAR(25),
  SEC_FORMAT VARCHAR(25),
  SEC_PRICE INT,
  SEC_DATE_COMP VARCHAR(10),
  C_CODE INT,
  PRIMARY KEY (SEC_NUM),
    FOREIGN KEY (C_CODE) REFERENCES COURSE
);

CREATE TABLE TAKES (
  PER_ID INT,
  SEC_NUM INT,
  PRIMARY KEY (PER_ID, SEC_NUM),
    FOREIGN KEY (PER_ID) REFERENCES PERSON,
    FOREIGN KEY (SEC_NUM) REFERENCES SECTION
);

CREATE TABLE REQUIRED_SKILL (
  JOB_CODE INT,
  KS_CODE INT,
  PRIMARY KEY (JOB_CODE, KS_CODE),
    FOREIGN KEY (JOB_CODE) REFERENCES JOB,
    FOREIGN KEY (KS_CODE) REFERENCES KNOWLEDGE_SKILLS
);