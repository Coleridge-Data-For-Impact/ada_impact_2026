

DROP TABLE IF EXISTS tr_state_impact_ada_training.ci_promis_cohort;
CREATE TABLE tr_state_impact_ada_training.ci_promis_cohort as 

/*
WITH promistart AS (
    SELECT 
        p.ssn,
        p.race,
        p.gender,
        p.education,
        p.last_employer_naics,
        p.veteran_status,
        p.week_ending_date,
        EXTRACT(YEAR FROM TO_DATE(p.week_ending_date, 'YYYYMMDD')) || 
        EXTRACT(QUARTER FROM TO_DATE(p.week_ending_date, 'YYYYMMDD')) AS quarter,
        ROW_NUMBER() OVER (
            PARTITION BY p.ssn 
            ORDER BY p.week_ending_date desc
        ) AS rn
    FROM ds_ar_dws.promis p
    WHERE quarter IN (20171, 20172)
)
SELECT
    promistart.*,
    cwc.*
FROM promistart
LEFT JOIN tr_state_impact_ada_training.ci_wioa_coenroll cwc
    ON promistart.ssn = cwc.social_security_number
   AND promistart.week_ending_date <= cwc.date_of_program_entry_wioa
WHERE promistart.rn = 1
ORDER BY promistart.ssn, cwc.date_of_program_entry_wioa;*/


WITH base AS (
    SELECT
        p.ssn,
        p.race,
        p.gender,
        p.education,
        p.last_employer_naics,
        --p.veteran_status,
        TO_DATE(p.week_ending_date, 'YYYYMMDD') AS week_end_date,
        EXTRACT(YEAR FROM TO_DATE(p.week_ending_date,'YYYYMMDD')) * 10
          + EXTRACT(QUARTER FROM TO_DATE(p.week_ending_date,'YYYYMMDD')) AS quarter_int
    FROM ds_ar_dws.promis p
    WHERE (EXTRACT(YEAR FROM TO_DATE(p.week_ending_date,'YYYYMMDD')) * 10
           + EXTRACT(QUARTER FROM TO_DATE(p.week_ending_date,'YYYYMMDD'))) IN (20171, 20172)
),
agg AS (
    SELECT
        ssn,
        COUNT(DISTINCT week_end_date) AS weeks_in_promis,
        MAX(week_end_date)            AS last_week_in_promis,
        min(week_end_date) as first_week_in_promis
    FROM base
    GROUP BY ssn
),
promistart AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY b.ssn
            ORDER BY b.week_end_date DESC
        ) AS rn
    FROM base b
)

SELECT
    ps.*,
    a.weeks_in_promis,
    a.last_week_in_promis,
    a.first_week_in_promis,
    cwc.date_of_program_entry_wioa ,
    cwc.date_of_program_exit_wioa ,
    cwc.dualenroll ,
    cwc.veteran_status ,  -- will be NULL for PROMIS-only SSNs
    DATEDIFF(week, a.last_week_in_promis, cwc.date_of_program_entry_wioa) AS weeks_between_last_promis_and_entry,
    DATEDIFF(day,  a.last_week_in_promis, cwc.date_of_program_entry_wioa) AS days_between_last_promis_and_entry
FROM promistart ps
JOIN agg a
  ON ps.ssn = a.ssn
LEFT JOIN tr_state_impact_ada_training.ci_wioa_coenroll cwc
  ON ps.ssn = cwc.social_security_number
 -- only keep coenrolls where entry is between first and last promis week and BEFORE 2017-12-31
 AND cwc.date_of_program_entry_wioa between a.first_week_in_promis and  a.last_week_in_promis 
 --AND cwc.date_of_program_entry_wioa < DATE '2017-12-31'
WHERE ps.rn = 1
ORDER BY ps.ssn, cwc.date_of_program_entry_wioa;

