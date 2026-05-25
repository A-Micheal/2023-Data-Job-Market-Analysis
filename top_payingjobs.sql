/* Analyzing the top paying remote jobs for data scientists and data analysts,
   and the skills that are in demand for these roles. */


/* The percentage of job postings for data scientists and data analysts out of all job postings */

SELECT
    COUNT(*) AS total_jobs,

    SUM(CASE
            WHEN LOWER(job_title_short) LIKE '%data analyst%'
              OR LOWER(job_title_short) LIKE '%data scientist%'
            THEN 1
            ELSE 0
        END) AS DS_DA_jobs,

    SUM(CASE
            WHEN LOWER(job_title_short) LIKE '%data analyst%'
            THEN 1
            ELSE 0
        END) AS analyst_count,

    SUM(CASE
            WHEN LOWER(job_title_short) LIKE '%data scientist%'
            THEN 1
            ELSE 0
        END) AS scientist_count,

    SUM(CASE
            WHEN job_title_short = 'Senior Data Scientist'
              OR job_title_short = 'Senior Data Analyst'
            THEN 1
            ELSE 0
        END) AS senior_roles_count,

    ROUND(
        100.0 * SUM(CASE
                        WHEN LOWER(job_title_short) LIKE '%data analyst%'
                          OR LOWER(job_title_short) LIKE '%data scientist%'
                        THEN 1
                        ELSE 0
                    END) / COUNT(*),
        2
    ) AS combined_data_roles_percentage,

    ROUND(
        100.0 * SUM(CASE
                        WHEN LOWER(job_title_short) LIKE '%senior%data analyst%'
                          OR LOWER(job_title_short) LIKE '%senior%data scientist%'
                        THEN 1
                        ELSE 0
                    END)
        /
        SUM(CASE
                WHEN LOWER(job_title_short) LIKE '%data analyst%'
                  OR LOWER(job_title_short) LIKE '%data scientist%'
                THEN 1
                ELSE 0
            END),
        2
    ) AS senior_roles_percentage

FROM job_postings_fact;


/* Data Analyst and Data Scientist roles make up 55.31% (435,684) of the total data job postings (787,686),
   indicating that data analyst and scientist roles form a significant and dominant portion of the job market.
   This highlights the strong demand and central importance of data analyst and scientist across industries.

   Only 15.23% of these roles are senior-level, showing that while opportunities in the data field are widely available,
   progression to senior positions is more limited and competitive.*/



-- The number of remote job postings for each role and percentages

-- adding a column to the table for better comparisons
ALTER TABLE job_postings_fact
ADD COLUMN cleaned_job_title TEXT;

UPDATE job_postings_fact
SET cleaned_job_title =
CASE
    WHEN job_title_short ILIKE '%Data Analyst%' THEN 'Data Analyst'
    WHEN job_title_short ILIKE '%Data Scientist%' THEN 'Data Scientist'
    ELSE 'Others'
END;


SELECT
    j.cleaned_job_title AS job_title,

    COUNT(*) FILTER (WHERE j.job_work_from_home = TRUE) AS remote,

    COUNT(*) FILTER (WHERE j.job_work_from_home = FALSE) AS non_remote,

    ROUND(
        COUNT(*) FILTER (WHERE j.job_work_from_home = TRUE) * 100.0
        / COUNT(*),
        2
    ) AS remote_percentage,

    ROUND(
        COUNT(*) FILTER (WHERE j.job_work_from_home = FAL4SE) * 100.0
        / COUNT(*),
        2
    ) AS non_remote_percentage

FROM job_postings_fact j
WHERE j.cleaned_job_title IN ('Data Analyst', 'Data Scientist');


/* Remote opportunities in 2023 data postings remain limited, with less than 10% of these jobs postings offering full remote flexibility.
   While Data Scientists have a slight advantage, the difference is minimal,
   suggesting that remote work availability is more influenced by experience level and specialization than by role alone.
   Consequently, remote positions are significantly more competitive and favor highly skilled candidates. */



-- Salary Distribution

-- Minimum, MAXIMUM, and Average salary for data analyst and data scientist roles
SELECT
    j.cleaned_job_title AS Job_title,
    COUNT(*) AS job_count,
    ROUND(AVG(j.salary_year_avg), 2) AS avg_salary,
    MIN(j.salary_year_avg) AS min_salary,
    MAX(j.salary_year_avg) AS max_salary
FROM job_postings_fact j
WHERE j.cleaned_job_title IN ('Data Analyst', 'Data Scientist')
    AND j.salary_year_avg IS NOT NULL
GROUP BY cleaned_job_title
ORDER BY avg_salary DESC;



-- Salary Analysis between Data Scientists and Data Analysts by job type

SELECT
    j.cleaned_job_title AS job_title,

    CASE
        WHEN j.job_work_from_home = TRUE THEN 'Remote'
        ELSE 'Non-Remote'
    END AS job_type,

    COUNT(*) AS job_count,

    ROUND(AVG(j.salary_year_avg), 0) AS avg_salary

FROM job_postings_fact j
WHERE j.cleaned_job_title IN ('Data Analyst', 'Data Scientist')
    AND j.salary_year_avg IS NOT NULL
GROUP BY
    j.cleaned_job_title,
    job_type
ORDER BY
    j.cleaned_job_title,
    job_type;



-- Details for the top paying remote jobs for data scientists and data analysts

-- Data Analyst Roles
SELECT
    j.job_title AS Job_title,
    c.name AS company_name,
    j.salary_year_avg AS Avg_salary,
    j.job_country AS Location
FROM job_postings_fact j
JOIN company_dim c
    ON j.company_id = c.company_id
WHERE j.salary_year_avg IS NOT NULL
    AND j.cleaned_job_title = 'Data Analyst'
    AND j.job_work_from_home = TRUE
ORDER BY j.salary_year_avg DESC
LIMIT 15;


-- Data Scientist Roles
SELECT
    j.job_title AS Job_title,
    c.name AS company_name,
    j.salary_year_avg AS Avg_salary,
    j.job_country AS location
FROM job_postings_fact j
JOIN company_dim c
    ON j.company_id = c.company_id
WHERE j.salary_year_avg IS NOT NULL
    AND j.cleaned_job_title = 'Data Scientist'
    AND j.job_work_from_home = TRUE
ORDER BY j.salary_year_avg DESC
LIMIT 15;



-- Skills Required for top paying remote jobs

-- Data Analyst Roles (Skill Frequency)
WITH top_paying_jobs AS (
    SELECT
        job_id,
        job_title,
        salary_year_avg
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
        AND cleaned_job_title = 'Data Analyst'
        AND job_work_from_home = TRUE
    ORDER BY salary_year_avg DESC
    LIMIT 15
)

SELECT
    s.skills,
    COUNT(*) AS skill_frequency
FROM top_paying_jobs t
JOIN skills_job_dim sk
    ON t.job_id = sk.job_id
JOIN skills_dim s
    ON sk.skill_id = s.skill_id
GROUP BY s.skills
HAVING COUNT(*) > 1
ORDER BY skill_frequency DESC;



-- Data Analyst Roles (Skill List)
WITH top_paying_jobs AS (
    SELECT
        job_id,
        job_title,
        salary_year_avg
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
        AND cleaned_job_title = 'Data Analyst'
        AND job_work_from_home = TRUE
    ORDER BY salary_year_avg DESC
    LIMIT 15
)

SELECT
    t.job_title,
    t.salary_year_avg,
    STRING_AGG(s.skills, ', ') AS skills_required
FROM top_paying_jobs t
JOIN skills_job_dim sk
    ON t.job_id = sk.job_id
JOIN skills_dim s
    ON sk.skill_id = s.skill_id
GROUP BY
    t.job_title,
    t.salary_year_avg
ORDER BY t.salary_year_avg DESC;



-- Data Scientist Roles (Skill Frequency)
WITH top_paying_jobs AS (
    SELECT
        job_id,
        job_title,
        salary_year_avg
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
        AND cleaned_job_title = 'Data Scientist'
        AND job_work_from_home = TRUE
    ORDER BY salary_year_avg DESC
    LIMIT 15
)

SELECT
    s.skills,
    COUNT(*) AS skill_frequency
FROM top_paying_jobs t
JOIN skills_job_dim sk
    ON t.job_id = sk.job_id
JOIN skills_dim s
    ON sk.skill_id = s.skill_id
GROUP BY s.skills
HAVING COUNT(*) > 1
ORDER BY skill_frequency DESC;



-- Data Scientist Roles (Skill List)
WITH top_paying_jobs AS (
    SELECT
        job_id,
        job_title,
        salary_year_avg
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
        AND cleaned_job_title = 'Data Scientist'
        AND job_work_from_home = TRUE
    ORDER BY salary_year_avg DESC
    LIMIT 15
)

SELECT
    t.job_title,
    t.salary_year_avg,
    STRING_AGG(s.skills, ', ') AS skills_required
FROM top_paying_jobs t
JOIN skills_job_dim sk
    ON t.job_id = sk.job_id
JOIN skills_dim s
    ON sk.skill_id = s.skill_id
GROUP BY
    t.job_title,
    t.salary_year_avg
ORDER BY t.salary_year_avg DESC;



-- Most in-demand skills

-- Data Scientist Jobs
SELECT
    j.cleaned_job_title,
    sk.skills,
    COUNT(*) AS num_jobs
FROM job_postings_fact j
JOIN skills_job_dim s
    ON j.job_id = s.job_id
JOIN skills_dim sk
    ON s.skill_id = sk.skill_id
WHERE j.cleaned_job_title = 'Data Scientist'
GROUP BY
    sk.skills,
    j.cleaned_job_title
ORDER BY num_jobs DESC
LIMIT 15;


-- Data Analyst Jobs
SELECT
    j.cleaned_job_title,
    sk.skills,
    COUNT(*) AS num_jobs
FROM job_postings_fact j
JOIN skills_job_dim s
    ON j.job_id = s.job_id
JOIN skills_dim sk
    ON s.skill_id = sk.skill_id
WHERE j.cleaned_job_title = 'Data Analyst'
GROUP BY
    sk.skills,
    j.cleaned_job_title
ORDER BY num_jobs DESC
LIMIT 15;



-- Skills vs Salary (Remote roles)

-- Data Analyst
SELECT
    sk.skills,
    COUNT(j.job_id) AS Demand,
    ROUND(AVG(j.salary_year_avg), 0) AS avg_salary
FROM job_postings_fact j
JOIN skills_job_dim s
    ON j.job_id = s.job_id
JOIN skills_dim sk
    ON s.skill_id = sk.skill_id
WHERE j.cleaned_job_title = 'Data Analyst'
    AND j.job_work_from_home = TRUE
    AND j.salary_year_avg IS NOT NULL
GROUP BY sk.skills
HAVING COUNT(j.job_id) > 10
ORDER BY avg_salary DESC, Demand DESC
LIMIT 25;


-- Data Scientist
SELECT
    sk.skills,
    COUNT(j.job_id) AS Demand,
    ROUND(AVG(j.salary_year_avg), 0) AS avg_salary
FROM job_postings_fact j
JOIN skills_job_dim s
    ON j.job_id = s.job_id
JOIN skills_dim sk
    ON s.skill_id = sk.skill_id
WHERE j.cleaned_job_title = 'Data Scientist'
    AND j.job_work_from_home = TRUE
    AND j.salary_year_avg IS NOT NULL
GROUP BY sk.skills
HAVING COUNT(j.job_id) > 10
ORDER BY avg_salary DESC, Demand DESC
LIMIT 25;