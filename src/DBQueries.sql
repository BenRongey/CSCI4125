/* 1. List a specific company’s workers by names. */
SELECT PER_NAME
FROM PERSON NATURAL JOIN WORK_HISTORY NATURAL JOIN JOB NATURAL JOIN COMPANY
WHERE DATE_END IS NULL AND COMP_ID = ?

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
SELECT JOB_CODE, JOB_TITLE
FROM work_history NATURAL JOIN JOB
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


/*7A. List the required knowledge/skills of a job and a job category in a readable format. (Two queries) */
SELECT KS_TITLE, KS_DESCRIPTION
FROM KNOWLEDGE_SKILLS NATURAL JOIN REQUIRED_SKILL
WHERE JOB_CODE = ?

/* 7B */
SELECT title,ks_code
FROM knowledge_skill JOIN required_skill NATURAL JOIN job
WHERE cate_code = ?


/* 8. Given a person’s identifier, list a person’s missing knowledge/skills for a specific job in a readable format
First instance of division */
SELECT title,ks_code
FROM (SELECT ks_code
      FROM required_skill
      WHERE job_code = ?
      MINUS
      SELECT ks_code
      FROM has_skill NATURAL JOIN knowledge_skill
      WHERE per_id = ?);


/*9.Given a person’s identifier and a job code, list the courses (course id and title) that each alone teaches all the missing knowledge/skills for this person to pursue the specific job.
--Dividion of course_ks by required skills by same c_code */
SELECT c_code, title
FROM course
WHERE NOT EXISTS(
    SELECT ks_code
    FROM required_skill
    WHERE job_code = ?
    MINUS
    SELECT ks_code
    FROM course_ks
    WHERE course.c_code = course_ks.c_code);


--10. Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the “quickest” solution for this worker. Show the course, section information and the completion date
--uses queiry 8 to build a missing skill table, then divides courses skills by it and selects the smallist date aka the quickest
WITH Missing_Skills AS (
  SELECT ks_code
  FROM required_skill
  WHERE job_code = ?
  MINUS
  SELECT ks_code
  FROM has_skill
  WHERE per_id = ?),

    Corses_Missing AS (
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
SELECT c_code, title, sec_num, end_date
FROM Corses_Missing NATURAL JOIN section
WHERE end_date = (SELECT MIN(end_date));


--11. . Suppose the skill gap of a worker and the requirement of a desired job can be covered by one course. Find the cheapest course to make up one’s skill gap by showing the course to take and the cost (of the section price).
--does exactly the same thing as number 10, but sorts by price
WITH Missing_Skills AS (
  SELECT ks_code
  FROM required_skill
  WHERE job_code = ?
  MINUS
  SELECT ks_code
  FROM has_skill
  WHERE per_id = ?),

    Corses_Missing AS (
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


--12. If query #9 returns nothing, then find the course sets that their combination covers all the missing knowledge/ skills for a person to pursue a specific job. The considered course sets will not include more than three courses. If multiple course sets are found, list the course sets (with their course IDs) in the order of the ascending order of the course sets’ total costs.
--CourseSet table needs to be added
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


--13. Given a person’s identifier, list all the job categories that a person is qualified for.
--looks like division but not.  backwards in a sence and not number of variables needed for division
SELECT cate_code,cat_description
FROM job_cat JC
WHERE NOT EXISTS(
    SELECT cate_code
    FROM core_skill CS
    WHERE JC.cate_code = CS.cate_code
    MINUS
    SELECT cate_code
    FROM has_skill NATURAL JOIN knowledge_skill
    WHERE per_id = ?);

--14. Given a person’s identifier, find the job with the highest pay rate for this person according to his/her skill possession.
WITH quilified_for(job_code,pay) AS (
    SELECT job_code,pay_rate
    FROM job J
    WHERE NOT EXISTS(
        SELECT ks_code
        FROM has_skill
        WHERE per_id = ?
        MINUS
        SELECT job_code
        FROM required_skill R
        WHERE J.job_code = R.job_code)

    SELECT job_code,pay
           FROM quilified_for
           WHERE pay = (select MAX(pay_rate) FROM quilified_for);


--15. Given a job code, list all the names along with the emails of the persons who are qualified for this job.
WITH quilified_for(job_code,pay) AS (
    SELECT job_code,pay_rate
    FROM job J
    WHERE NOT EXISTS(
        SELECT ks_code
        FROM has_skill
        MINUS
        SELECT job_code
        FROM required_skill R
        WHERE J.job_code = R.job_code, job_code = ?)

    SELECT name,email
    FROM quilified_for;


--16. When a company cannot find any qualified person for a job, a secondary solution is to find a person who is almost qualified to the job. Make a “missing-one” list that lists people who miss only one skill for a specified job.


--17. List each of the skill code and the number of people who misses the skill and are in the missing-one list for a given job code in the ascending order of the people counts.


--18.  Suppose there is a new job that has nobody qualified. List the persons who miss the least number of skills that are required by this job and report the “least number”.


--19. For a specified job code and a given small number k, make a “missing-k” list that lists the people’s IDs and the number of missing skills for the people who miss only up to k skills in the ascending order of missing skills


--20. Given a job code and its corresponding missing-k list specified in Question 19. Find every skill that is needed by at least one person in the given missing-k list. List each skill code and the number of people who need it in the descending order of the people counts.


--21.In a local or national crisis, we need to find all the people who once held a job of the special job category identifier.
SELECT per_id
FROM work_history NATURAL JOIN job
WHERE cate_code = ?, end_date != NULL;


--22. Find all the unemployed people who once held a job of the given job identifier.
SELECT per_id
FROM work_history NATURAL JOIN job
WHERE job_code = ?, start_date = NULL;

--tu's version
--SELECT per_id
--FROM work_history
--WHERE job_code = ?
--MINUS
--SELECT per_id
--FROM job


--23. Find out the biggest employer in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
--A.
WITH total_employee(name, numemploy) AS (
    SELECT name,COUNT(per_id)
    FROM work_history NATURAL JOIN job NATURAL JOIN company
    WHERE end_date = NULL
    GROUP BY comp_id)

SELECT name
FROM total_employee
WHERE numemploy = (select MAX(numemploy) FROM total_employee);

--B.
WITH Total_hourly(comp_id, sum_hourly) AS(
    SELECT comp_id, SUM(pay_rate)*1920
    FROM job NATURAL JOIN work_history
    WHERE pay_type = "h" AND date_end is NULL),

    Total_salary(comp_id, sum_salary) AS(
      SELECT comp_id, SUM(pay_rate)
      FROM job NATURAL JOIN work_history
      WHERE pay_type = "s" AND date_end is NULL)

Total_pay(THcomp_id, TScomp_id, total_pay) AS (
SELECT Total_hourly.comp_id, Total_salary.comp_id, (sum_hourly + sum_salary)
FROM Total_salary,Total_hourly
WHERE Total_salary.comp_id = Total_hourly.comp_id
GROUP BY Total_hourly.comp_id, Total_salary.comp_id, (sum_hourly + sum_salary))

SELECT name
FROM Total_pay, company
WHERE total_pay = (SELECT MAX(total_pay) FROM Total_pay);


--24.  Find out the job distribution among business sectors; find out the biggest sector in terms of number of employees and the total amount of salaries and wages paid to employees. (Two queries)
--A.
SELECT sec_name, COUNT(comp_id)
FROM business_sector NATURAL JOIN company)
WHERE primary_sector = sec_name)
ORDER BY COUNT(comp_id) ASC;
--B.
--a repeat of 23 with an extra business sector layer