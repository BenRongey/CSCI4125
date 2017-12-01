/* 1. List a specific company’s workers by names. */
SELECT PER_NAME
FROM person natural join work_history natral join job natural join company
WHERE date_end IS null AND comp_name = ?;

/* 2. List a specific company’s staff by salary in descending order. */
SELECT pay_rate
FROM job NATURAL JOIN work_history NATURAL JOIN company
WHERE comp_name = ?, pay_type = "s"
ORDER BY pay_rate DESC;

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
SELECT job_code
FROM work_history
WHERE per_id = ?


/* 5. Given a person’s identifier, list this person’s knowledge/skills in a readable format. */
SELECT KS_TITLE, ks_code
FROM KNOWLEDGE_SKILLS NATURAL JOIN has_skill
WHERE per_id = ?


/* 6. Given a person’s identifier, list the skill gap between the requirements of this worker’ job(s) and his/her skills. */
SELECT ks_code
FROM work_history NATURAL JOIN required_skill
WHERE per_id = ?
MINUS
SELECT ks_code
FROM has_skill
WHERE per_id = ?;


/* 7. List the required knowledge/skills of a job and a job category in a readable format. (Two queries)
--A. */
SELECT ks_title, ks_description
FROM knowledge_skills NATURAL JOIN required_skill
WHERE job_code = ?;

/* 7B */
SELECT ks_title, ks_description
FROM knowledge_skills JOIN required_skill NATURAL JOIN job
WHERE cate_code = ?;


/* 8. Given a person’s identifier, list a person’s missing knowledge/skills for a specific job in a readable format
--First instance of division  */
SELECT ks_title, ks_description
FROM (SELECT ks_code
      FROM required_skill
      WHERE job_code = ?
      MINUS
      SELECT ks_code
      FROM has_skill
      WHERE per_id = ?) NATURAL JOIN knowledge_skills;


/* 9.Given a person’s identifier and a job code, list the courses (course id and title) that each alone teaches all the missing knowledge/skills for this person to pursue the specific job.
--Dividion of course_ks by required skills by same c_code  */
WITH Missing_Skills (ks_code) AS (
  SELECT ks_code
  FROM required_skill
  WHERE job_code = 2
  MINUS
  SELECT ks_code
  FROM has_skill
  WHERE per_id = 2)

SELECT c_code, c_title
FROM course, Missing_Skills
WHERE NOT EXISTS(
    SELECT ks_code
    FROM Missing_Skills
    MINUS
    SELECT ks_code
    FROM course_ks
    WHERE course.c_code = course_ks.c_code);


/* 10. Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the “quickest” solution for this worker. Show the course, section information and the completion date
--uses queiry 8 to build a missing skill table, then divides courses skills by it and selects the smallist date aka the quickest */
WITH Missing_Skills (ks_code) AS (
  SELECT ks_code
  FROM required_skill
  WHERE job_code = 13
  MINUS
  SELECT ks_code
  FROM has_skill
  WHERE per_id = 2),

    Courses_Missing (c_code, c_title) AS (
      SELECT c_code,c_title
      FROM course, Missing_Skills
      WHERE NOT EXISTS(
          SELECT ks_code
          FROM Missing_Skills
          MINUS
          SELECT ks_code
          FROM course_ks
          WHERE course.c_code = course_ks.c_code)
  )
SELECT c_code, c_title, sec_num, sec_date_comp
FROM Courses_Missing NATURAL JOIN section
WHERE sec_date_comp = (SELECT MIN(sec_date_comp)
                       FROM Courses_Missing NATURAL JOIN section);


/* 11. . Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the cheapest course to make up one’s skill gap by showing the course to take and the cost (of the section price).
--does exactly the same thing as number 10, but sorts by price */
WITH Missing_Skills (ks_code) AS (
  SELECT ks_code
  FROM required_skill
  WHERE job_code = ?
  MINUS
  SELECT ks_code
  FROM has_skill
  WHERE per_id = ?),

    Corses_Missing (c_code, title) AS (
      SELECT c_code,title
      FROM course
      WHERE NOT EXISTS(
          SELECT ks_code
          FROM Missing_Skills
          MINUS
          SELECT ks_code
          FROM course_ks
          WHERE course.c_code = course_ks.c_code)
  )
SELECT c_code, title, sec_num, price
FROM Corses_Missing NATURAL JOIN section
WHERE end_date = (SELECT MIN(price) FROM Corses_Missing NATURAL JOIN section);


/* 12. If query #9 returns nothing, then find the course sets that their combination covers all the missing knowledge/ skills for a person to pursue a specific job. The considered course sets will not include more than three courses. If multiple course sets are found, list the course sets (with their course IDs) in the order of the ascending order of the course sets’ total costs.
--CourseSet table needs to be added */
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
WHERE size = (SELECT MIN(SIZE) FROM Cover_CSet);


/* 13. Given a person’s identifier, list all the job categories that a person is qualified for.
--looks like division but not.  backwards in a sence and not number of variables needed for division */
SELECT cate_code, cate_decription
FROM job_cate JC
WHERE NOT EXISTS(
    SELECT ks_code
    FROM knowledge_cluster KC
    WHERE JC.cate_code = KC.cate_code
    MINUS
    SELECT ks_code
    FROM has_skill
    WHERE per_id = 1);


/* 14. Given a person’s identifier, find the job with the highest pay rate for this person according to his/her skill possession. */
WITH quilified_for(job_code) AS (
    SELECT job_code
    FROM job J
    WHERE NOT EXISTS(
        SELECT ks_code
        FROM required_skill RS
        WHERE J.job_code = RS.job_code
        MINUS
        SELECT ks_code
        FROM has_skill
        WHERE per_id = 1)
),
    Total_pay(job_code, salary) AS (
      SELECT job_code,
        sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
            WHEN PAY_TYPE='S' THEN PAY_RATE
            END) SALARY
      FROM JOB NATURAL JOIN WORK_HISTORY
      Where DATE_END is NULL
      GROUP BY job_code
  )

SELECT job_code, salary
FROM quilified_for NATURAL JOIN Total_pay
WHERE salary = (SELECT MAX(salary) FROM Total_pay);


/* 15. Given a job code, list all the names along with the emails of the persons who are qualified for this job. */
SELECT per_name, email
FROM person P
WHERE NOT EXISTS(
    SELECT ks_code
    FROM required_skill
    WHERE job_code = 5
    MINUS
    SELECT ks_code
    FROM has_skill HS
    WHERE P.per_id = HS.per_id);


/* 16. When a company cannot find any qualified person for a job, a secondary solution is to find a person who is almost qualified to the job. Make a “missing-one” list that lists people who miss only one skill for a specified job. */

WITH Missing_Skills (per_id, ks_code) AS (
  SELECT per_id, ks_code
  FROM person, required_skill
  WHERE job_code = 2
  MINUS
  SELECT *
  FROM has_skill),

    Missing_Count (per_id, cnt) AS (
      SELECT per_id, COUNT(ks_code) cnt
      FROM Missing_Skills
      GROUP BY per_id)

SELECT per_id
FROM Missing_Count
WHERE cnt = 1;
/* 17. List each of the skill code and the number of people who misses the skill and are in the missing-one list for a given job code in the ascending order of the people counts. */

WITH Missing_Skills (per_id, ks_code) AS (
  SELECT per_id, ks_code
  FROM person, required_skill
  WHERE job_code = 1
  MINUS
  SELECT *
  FROM has_skill),

    Missing_Count (ks_code, cnt) AS (
      SELECT ks_code, COUNT(per_id) cnt
      FROM Missing_Skills
      GROUP BY ks_code)

SELECT *
FROM Missing_Count
ORDER BY cnt ASC;
/* 18.  Suppose there is a new job that has nobody qualified. List the persons who miss the least number of skills that are required by this job and report the “least number”. */


WITH Missing_Skills (per_id, ks_code) AS (
  SELECT per_id, ks_code
  FROM person, required_skill
  WHERE job_code = ?
  MINUS
  SELECT *
  FROM has_skill),

    Missing_Count (per_id, cnt) AS (
      SELECT per_id, COUNT(ks_code) cnt
      FROM Missing_Skills
      GROUP BY per_id),

    SELECT per_id
  FROM Missing_Count
  WHERE cnt = (SELECT MIN(cnt)
  FROM Missing_Count);
/* 19. For a specified job code and a given small number k, make a “missing-k” list that lists the people’s IDs and the number of missing skills for the people who miss only up to k skills in the ascending order of missing skills */

WITH Missing_Skills (per_id, ks_code) AS (
  SELECT per_id, ks_code
  FROM person, required_skill
  WHERE job_code = 1
  MINUS
  SELECT *
  FROM has_skill),

    Missing_Count (per_id, cnt) AS (
      SELECT per_id, COUNT(ks_code) cnt
      FROM Missing_Skills
      GROUP BY per_id)

SELECT per_id, cnt
FROM Missing_Count
WHERE cnt = 2
ORDER BY cnt ASC;
/*20. Given a job code and its corresponding missing-k list specified in Question 19. Find every skill that is needed by at least one person in the given missing-k list. List each skill code and the number of people who need it in the descending order of the people counts.
--run 19 then */


WITH Missing_Skills (per_id, ks_code) AS (
  SELECT per_id, ks_code
  FROM person, required_skill
  WHERE job_code = ?
  MINUS
  SELECT *
  FROM has_skill),


    SELECT ks_code, COUNT(per_id) cnt
                                  FROM Missing_Skills
                                  GROUP BY ks_code
                                  ORDER BY cnt DESC;

/* 21.In a local or national crisis, we need to find all the people who once held a job of the special job category identifier. */
SELECT per_id
FROM work_history NATURAL JOIN job
WHERE cate_code = ?, end_date IS NOT NULL;


/* 22. Find all the unemployed people who once held a job of the given job identifier. */
SELECT per_id
FROM work_history NATURAL JOIN job
WHERE job_code = ? AND start_date IS NULL;
/*
--tu's version
--SELECT per_id
--FROM work_history
--WHERE job_code = ?
--MINUS
--SELECT per_id
--FROM job
*/

/* 23. Find out the biggest employer in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
--A. */
WITH total_employee(comp_name, numemploy) AS (
    SELECT comp_name, COUNT(per_id)
    FROM work_history NATURAL JOIN job NATURAL JOIN company
    WHERE date_end IS NULL
    GROUP BY (comp_name)
)

SELECT comp_name
FROM total_employee
WHERE numemploy = (select MAX(numemploy) FROM total_employee);

/* 23B.  */

WITH Total_pay(comp_id, COMP_NAME, salary) AS (
    SELECT COMP_ID, COMP_NAME,sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
                                  WHEN PAY_TYPE='S' THEN PAY_RATE
                                  END) SALARY
    FROM JOB NATURAL JOIN COMPANY NATURAL JOIN WORK_HISTORY
    Where DATE_END is NULL
    GROUP BY COMP_ID, COMP_NAME
)

SELECT comp_name
FROM Total_pay
WHERE salary = (SELECT MAX(salary) FROM Total_pay);


/* 24.  Find out the job distribution among business sectors; find out the biggest sector in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
--A. */
SELECT PRIMARY_SECTOR, COUNT(comp_id)
FROM business_sector NATURAL JOIN company)
WHERE primary_sector = sec_name)
ORDER BY COUNT(comp_id) ASC;

/* --B.
--a repeat of 23 with an extra business sector layer */

WITH Total_pay(comp_id, salary) AS (
    SELECT COMP_ID,sum(CASE WHEN PAY_TYPE='H' THEN JOB.PAY_RATE*1920
                       WHEN PAY_TYPE='S' THEN PAY_RATE
                       END) SALARY
    FROM JOB NATURAL JOIN COMPANY NATURAL JOIN WORK_HISTORY
    Where DATE_END is NULL
    GROUP BY COMP_ID, COMP_NAME
)

SELECT PRIMARY_SECTOR
FROM Total_pay NATURAL JOIN company
WHERE salary = (SELECT MAX(salary) FROM Total_pay);


/* --26. */