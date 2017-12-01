/* 1. List a specific company’s workers by names. */
SELECT PER_NAME
FROM PERSON NATURAL JOIN WORK_HISTORY NATURAL JOIN JOB NATURAL JOIN COMPANY
WHERE DATE_END IS NULL AND COMP_NAME = ?

/* 2. List a specific company’s staff by salary in descending order. */
SELECT PAY_RATE
FROM JOB NATURAL JOIN WORK_HISTORY NATURAL JOIN COMPANY
WHERE COMP_NAME = ? AND PAY_TYPE = 'S'
ORDER BY PAY_RATE DESC

/* 3. List companies’ labor cost (total salaries and wage rates by 1920 hours) in descending order. */
SELECT COMP_ID, COMP_NAME,
  sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
      WHEN PAY_TYPE='S' THEN PAY_RATE
      END) SALARY
FROM JOB NATURAL JOIN COMPANY NATURAL JOIN WORK_HISTORY
Where DATE_END is NULL
GROUP BY COMP_ID, COMP_NAME
ORDER BY SALARY DESC

/* 4. Given a person’s identifier, find all the jobs this person is currently holding and worked in the past. */
SELECT JOB_CODE
FROM WORK_HISTORY
WHERE PER_ID = ?


/* 5. Given a person’s identifier, list this person’s knowledge/skills in a readable format. */
SELECT KS_TITLE, KS_CODE
FROM KNOWLEDGE_SKILLS NATURAL JOIN HAS_SKILL
WHERE PER_ID = ?


/* 6. Given a person’s identifier, list the skill gap between the requirements of this worker’ job(s) and his/her skills. */
SELECT KS_CODE
FROM WORK_HISTORY NATURAL JOIN REQUIRED_SKILL
WHERE PER_ID = ?
MINUS
SELECT KS_CODE
FROM HAS_SKILL
WHERE PER_ID = ?


/* 7. List the required knowledge/skills of a job and a job category in a readable format. (Two queries)
--A. */
SELECT KS_TITLE, KS_DESCRIPTION
FROM KNOWLEDGE_SKILLS NATURAL JOIN REQUIRED_SKILL
WHERE JOB_CODE = ?

/* 7B */
SELECT KS_TITLE, KS_DESCRIPTION
FROM KNOWLEDGE_SKILLS JOIN REQUIRED_SKILL NATURAL JOIN JOB
WHERE CATE_CODE = ?


/* 8. Given a person’s identifier, list a person’s missing knowledge/skills for a specific job in a readable format */
SELECT KS_TITLE, KS_DESCRIPTION
FROM (SELECT KS_CODE
      FROM REQUIRED_SKILL
      WHERE JOB_CODE = ?
      MINUS
      SELECT KS_CODE
      FROM HAS_SKILL
      WHERE PER_ID = ?) NATURAL JOIN KNOWLEDGE_SKILLS


/* 9.Given a person’s identifier and a job code, list the courses (course id and title) that each alone teaches all the missing knowledge/skills for this person to pursue the specific job. */
WITH Missing_Skills (KS_CODE) AS (
  SELECT KS_CODE
  FROM REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT KS_CODE
  FROM HAS_SKILL
  WHERE PER_ID = ?)

SELECT C_CODE, C_TITLE
FROM COURSE, Missing_Skills
WHERE NOT EXISTS(
    SELECT KS_CODE
    FROM Missing_Skills
    MINUS
    SELECT KS_CODE
    FROM COURSE_KS
    WHERE COURSE.C_CODE = COURSE_KS.C_CODE)


/* 10. Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the “quickest” solution for this worker. Show the course, section information and the completion date
--uses query 8 to build a missing skill table, then divides courses skills by it and selects the smallest date aka the quickest */
WITH Missing_Skills (KS_CODE) AS (
  SELECT KS_CODE
  FROM REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT KS_CODE
  FROM HAS_SKILL
  WHERE PER_ID = ?),

    Courses_Missing (C_CODE, C_TITLE) AS (
      SELECT C_CODE, C_TITLE
      FROM COURSE, Missing_Skills
      WHERE NOT EXISTS(
          SELECT KS_CODE
          FROM Missing_Skills
          MINUS
          SELECT KS_CODE
          FROM COURSE_KS
          WHERE COURSE.C_CODE = COURSE_KS.C_CODE)
  )
SELECT C_CODE, C_TITLE, SEC_NUM, SEC_DATE_COMP
FROM Courses_Missing NATURAL JOIN SECTION
WHERE SEC_DATE_COMP = (SELECT MIN(SEC_DATE_COMP)
                       FROM Courses_Missing NATURAL JOIN SECTION)


/* 11. . Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the cheapest course to make up one’s skill gap by showing the course to take and the cost (of the section price).
--does exactly the same thing as number 10, but sorts by price */
WITH Missing_Skills (KS_CODE) AS (
  SELECT KS_CODE
  FROM REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT KS_CODE
  FROM HAS_SKILL
  WHERE PER_ID = ?),

    Corses_Missing (C_CODE, C_TITLE) AS (
      SELECT C_CODE, C_TITLE
      FROM COURSE
      WHERE NOT EXISTS(
          SELECT KS_CODE
          FROM Missing_Skills
          MINUS
          SELECT KS_CODE
          FROM COURSE_KS
          WHERE COURSE.C_CODE = COURSE_KS.C_CODE)
  )
SELECT C_CODE, C_TITLE, SEC_NUM, SEC_PRICE
FROM Corses_Missing NATURAL JOIN SECTION
WHERE SEC_DATE_COMP = (SELECT MIN(SEC_PRICE) FROM Corses_Missing NATURAL JOIN SECTION);


/* 12. If query #9 returns nothing, then find the course sets that their combination covers all the missing knowledge/ skills for a person to pursue a specific job. The considered course sets will not include more than three courses. If multiple course sets are found, list the course sets (with their course IDs) in the order of the ascending order of the course sets’ total costs. */

/* This query doesn't work for our DB.  It is an exact copy of an answer given by Dr. Tu in class */
WITH CourseSet_Skill(csetID, ks_code) AS (
  SELECT csetID, ks_code
  FROM CourseSet CSet JOIN course_ks CS ON CSet.c_code1=CS.c_code
  UNION
  SELECT csetID, ks_code
  FROM CourseSet CSet JOIN course_ks CS ON CSet.c_code2=CS.c_code
  UNION
  SELECT csetID, sk_code
  FROM CourseSet CSet JOIN course_ks CS ON CSet.c_code3=CS.c_code;
)

Cover_CSet(csetID, setsize) AS (
SELECT csetID
FROM CourseSet CSet
WHERE NOT EXISTS (
SELECT sk_code
FROM MissingSkill
MINUS
SELECT sk_code
FROM CourseSet_Skill CSSk
WHERE CSSk.csetID = Cset.csetID
)
)

SELECT c_code1, c_code2, c_code3
FROM Cover_CSet NATURAL JOIN CourseSet
WHERE size = (SELECT MIN(SIZE) FROM Cover_CSet)


/* 13. Given a person’s identifier, list all the job categories that a person is qualified for. */
SELECT CATE_CODE, CATE_DECRIPTION
FROM JOB_CATE JC
WHERE NOT EXISTS(
    SELECT KS_CODE
    FROM KNOWLEDGE_CLUSTER KC
    WHERE JC.CATE_CODE = KC.CATE_CODE
    MINUS
    SELECT KS_CODE
    FROM HAS_SKILL
    WHERE PER_ID = ?)


/* 14. Given a person’s identifier, find the job with the highest pay rate for this person according to his/her skill possession. */
WITH Qualified_For(JOB_CODE) AS (
    SELECT JOB_CODE
    FROM JOB J
    WHERE NOT EXISTS(
        SELECT KS_CODE
        FROM REQUIRED_SKILL RS
        WHERE J.JOB_CODE = RS.JOB_CODE
        MINUS
        SELECT KS_CODE
        FROM HAS_SKILL
        WHERE HAS_SKILL.PER_ID = ?)
),
    Total_pay(JOB_CODE, SALARY) AS (
      SELECT JOB_CODE,
        sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
            WHEN PAY_TYPE='S' THEN PAY_RATE
            END) SALARY
      FROM JOB NATURAL JOIN WORK_HISTORY
      WHERE DATE_END IS NULL
      GROUP BY JOB_CODE
  )

SELECT JOB_CODE, SALARY
FROM Qualified_For NATURAL JOIN Total_pay
WHERE SALARY = (SELECT MAX(SALARY) FROM Total_pay)


/* 15. Given a job code, list all the names along with the emails of the persons who are qualified for this job. */
SELECT PER_NAME, EMAIL
FROM PERSON P
WHERE NOT EXISTS(
    SELECT KS_CODE
    FROM REQUIRED_SKILL
    WHERE JOB_CODE = ?
    MINUS
    SELECT KS_CODE
    FROM HAS_SKILL HS
    WHERE P.PER_ID = HS.PER_ID)


/* 16. When a company cannot find any qualified person for a job, a secondary solution is to find a person who is almost qualified to the job. Make a “missing-one” list that lists people who miss only one skill for a specified job. */

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),

    Missing_Count (PER_ID, CNT) AS (
      SELECT PER_ID, COUNT(KS_CODE) CNT
      FROM Missing_Skills
      GROUP BY PER_ID)

SELECT PER_ID
FROM Missing_Count
WHERE CNT = 1

/* 17. List each of the skill code and the number of people who misses the skill and are in the missing-one list for a given job code in the ascending order of the people counts. */

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),

    Missing_Count (KS_CODE, CNT) AS (
      SELECT KS_CODE, COUNT(PER_ID) CNT
      FROM Missing_Skills
      GROUP BY KS_CODE)

SELECT *
FROM Missing_Count
ORDER BY CNT ASC

/* 18.  Suppose there is a new job that has nobody qualified. List the persons who miss the least number of skills that are required by this job and report the “least number”. */

/* TODO FIX THIS ONE */

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),

    Missing_Count (PER_ID, CNT) AS (
      SELECT PER_ID, COUNT(KS_CODE) CNT
      FROM Missing_Skills
      GROUP BY PER_ID),

  SELECT per_id
  FROM Missing_Count
  WHERE CNT = (SELECT MIN(CNT)
  FROM Missing_Count);

/* 19. For a specified job code and a given small number k, make a “missing-k” list that lists the people’s IDs and the number of missing skills for the people who miss only up to k skills in the ascending order of missing skills */

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),

    Missing_Count (PER_ID, CNT) AS (
      SELECT PER_ID, COUNT(KS_CODE) CNT
      FROM Missing_Skills
      GROUP BY PER_ID)

SELECT PER_ID, CNT
FROM Missing_Count
WHERE CNT = 2
ORDER BY CNT ASC

/*20. Given a job code and its corresponding missing-k list specified in Question 19. Find every skill that is needed by at least one person in the given missing-k list. List each skill code and the number of people who need it in the descending order of the people counts. */

/* TODO FIX THIS ONE */

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),

    Missing_Count (PER_ID, CNT) AS (
      SELECT PER_ID, COUNT(KS_CODE) CNT
      FROM Missing_Skills
      GROUP BY PER_ID)

SELECT PER_ID, CNT
FROM Missing_Count
WHERE CNT = 2
ORDER BY CNT ASC

WITH Missing_Skills (PER_ID, KS_CODE) AS (
  SELECT PER_ID, KS_CODE
  FROM PERSON, REQUIRED_SKILL
  WHERE JOB_CODE = ?
  MINUS
  SELECT *
  FROM HAS_SKILL),


    SELECT KS_CODE, COUNT(PER_ID) CNT
    FROM Missing_Skills
    GROUP BY KS_CODE
    ORDER BY CNT DESC;

/* 21.In a local or national crisis, we need to find all the people who once held a job of the special job category identifier. */

SELECT PER_ID
FROM WORK_HISTORY NATURAL JOIN JOB
WHERE CATE_CODE = ? AND DATE_END IS NOT NULL


/* 22. Find all the unemployed people who once held a job of the given job identifier. */

SELECT PER_ID
FROM WORK_HISTORY NATURAL JOIN JOB
WHERE JOB_CODE = ? AND DATE_START IS NULL

/*
  tu's version for 22

  SELECT per_id
  FROM work_history
  WHERE job_code = ?
  MINUS
  SELECT per_id
  FROM job
*/

/* 23. Find out the biggest employer in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
  A. */

WITH Total_employee(COMP_NAME, NUM_EMPLOY) AS (
    SELECT COMP_NAME, COUNT(PER_ID)
    FROM WORK_HISTORY NATURAL JOIN JOB NATURAL JOIN COMPANY
    WHERE DATE_END IS NULL
    GROUP BY (COMP_NAME)
)

SELECT COMP_NAME
FROM Total_employee
WHERE NUM_EMPLOY = (SELECT MAX(NUM_EMPLOY) FROM Total_employee)

/* 23B.  */

WITH Total_pay(COMP_ID, COMP_NAME, SALARY) AS (
    SELECT COMP_ID, COMP_NAME, sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
                                  WHEN PAY_TYPE='S' THEN PAY_RATE
                                  END) SALARY
    FROM JOB NATURAL JOIN COMPANY NATURAL JOIN WORK_HISTORY
    WHERE DATE_END IS NULL
    GROUP BY COMP_ID, COMP_NAME
)

SELECT COMP_NAME
FROM Total_pay
WHERE SALARY = (SELECT MAX(SALARY) FROM Total_pay)

/* 24.  Find out the job distribution among business sectors; find out the biggest sector in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
  A. */
/* TODO FIX THIS ONE */

SELECT PRIMARY_SECTOR, COUNT(COMP_ID)
FROM BUSINESS_SECTOR NATURAL JOIN COMPANY
WHERE PRIMARY_SECTOR = SEC_NAME
ORDER BY COUNT(COMP_ID) ASC;

/* 24B.
A repeat of 23 with an extra business sector layer */

WITH Total_pay(COMP_ID, SALARY) AS (
    SELECT COMP_ID,sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
                       WHEN PAY_TYPE='S' THEN PAY_RATE
                       END) SALARY
    FROM JOB NATURAL JOIN COMPANY NATURAL JOIN WORK_HISTORY
    WHERE DATE_END IS NULL
    GROUP BY COMP_ID, COMP_NAME
)

SELECT PRIMARY_SECTOR
FROM Total_pay NATURAL JOIN COMPANY
WHERE SALARY = (SELECT MAX(SALARY) FROM Total_pay)

/* 25. */

/* 26. */

/* 27. */

/* 28. */