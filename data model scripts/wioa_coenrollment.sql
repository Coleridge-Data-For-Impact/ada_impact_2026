

DROP TABLE IF EXISTS tr_state_impact_ada_training.ci_wioa_coenroll;
CREATE TABLE tr_state_impact_ada_training.ci_wioa_coenroll as 

WITH wagner AS (
  SELECT
    p.social_security_number,
    p.wagner_peyser_employment_service_wioa,
    p.date_of_program_entry_wioa,
    p.date_of_program_exit_wioa,
    p.type_of_training_service_1_wioa  AS wagner_train1,
    p.type_of_training_service_2_wioa AS wagner_train2,
    p.type_of_training_service_3_wioa AS wagner_train3,
    p.veteran_status ,
    CAST('wagner_peyser' AS varchar) AS program2,
    ROW_NUMBER() OVER (
      PARTITION BY p.social_security_number
      ORDER BY p.date_of_program_entry_wioa ASC
    ) AS rn
  FROM ds_ar_dws.pirl_update p
  WHERE p.sheetnameproperty = 'Wagner-Peyser'
    AND p.wagner_peyser_employment_service_wioa = '1'
  QUALIFY rn = 1
),
adult_wioa AS (
  SELECT
    p.social_security_number,
    p.date_of_program_entry_wioa,
    p.date_of_program_exit_wioa,
    p.type_of_training_service_1_wioa AS aw_train1,
    p.type_of_training_service_2_wioa AS aw_train2,
    p.type_of_training_service_3_wioa AS aw_train3,
    CAST('adult wioa' AS varchar) AS program1,
    p.veteran_status ,
    ROW_NUMBER() OVER (
      PARTITION BY p.social_security_number
      ORDER BY p.date_of_program_entry_wioa ASC
    ) AS rn
  FROM ds_ar_dws.pirl_update p
  WHERE p.sheetnameproperty = 'Adult'
    AND p.adult_wioa IN (1,2,3)
  QUALIFY rn = 1
)
SELECT
  COALESCE(a.social_security_number, w.social_security_number) AS social_security_number,
  COALESCE(a.date_of_program_entry_wioa, w.date_of_program_entry_wioa) AS date_of_program_entry_wioa,
  COALESCE(a.date_of_program_exit_wioa,  w.date_of_program_exit_wioa)  AS date_of_program_exit_wioa,
  a.program1,
  w.program2,
  CASE
    WHEN w.program2 = 'wagner_peyser' AND a.program1 IS NOT NULL THEN 'dual enrolled'
    WHEN w.program2 IS NULL AND a.program1 = 'adult wioa'          THEN 'adult wioa only'
    WHEN w.program2 = 'wagner_peyser' AND a.program1 IS NULL       THEN 'wagner peyser only'
  END AS dualenroll,
  case 
  	when a.veteran_status = 1 or w.veteran_status = 1 then 'veteran'
  	when a.veteran_status = 0 or w.veteran_status = 0 then 'non veteran'
  end as veteran_status
  
FROM adult_wioa a
FULL OUTER JOIN wagner w
  ON a.social_security_number = w.social_security_number
-- If you also require the *earliest dates* to match exactly, add:
-- AND a.date_of_program_entry_wioa = w.date_of_program_entry_wioa
ORDER BY COALESCE(a.date_of_program_entry_wioa, w.date_of_program_entry_wioa);


/*
select count(1), pu.veteran_status
from ds_ar_dws.pirl_update pu 
group by pu.veteran_status 



CREATE TABLE tr_state_impact_ada_training.ci_wioa_coenroll as 
with wagner as (
  select
    p.social_security_number,
    p.wagner_peyser_employment_service_wioa,
    p.date_of_program_entry_wioa,
    p.date_of_program_exit_wioa,
    p.type_of_training_service_1_wioa as wagner_train1,
    p.type_of_training_service_1_wioa as wagner_train2,
    p.type_of_training_service_1_wioa as wagner_train3,
    p.veteran_status ,
    cast('wagner_peyser' as varchar) as program2
  from ds_ar_dws.pirl_update p
  where p.sheetnameproperty = 'Wagner-Peyser'
    and p.wagner_peyser_employment_service_wioa = '1'
  group by 1,2,3,4,5,6,7,8
),

adult_wioa as (
  select
    p.social_security_number,
    p.date_of_program_entry_wioa,
    p.date_of_program_exit_wioa,
    p.type_of_training_service_1_wioa as aw_train1,
    p.type_of_training_service_1_wioa as aw_train2,
    p.type_of_training_service_1_wioa as aw_train3,
    p.veteran_status ,
    cast('adult wioa' as varchar) as program1
  from ds_ar_dws.pirl_update p
  where p.sheetnameproperty = 'Adult'
    and p.adult_wioa in (1,2,3)
  group by 1,2,3,4,5,6,7,8
)

select
  adult_wioa.social_security_number,
  adult_wioa.date_of_program_entry_wioa,
  adult_wioa.date_of_program_exit_wioa,
  adult_wioa.program1,
  wagner.program2,
  wagner.veteran_status,
  
  case
    when wagner.program2 = 'wagner_peyser' and adult_wioa.program1 is not null then 'dual enrolled'
    when wagner.program2 is null and adult_wioa.program1 = 'adult wioa' then 'adult wioa only'
    when wagner.program2 = 'wagner_peyser' and adult_wioa.program1 is null then 'wagner peyser only'
  end as dualenroll
from adult_wioa
 full outer join wagner
  on adult_wioa.social_security_number = wagner.social_security_number
  and adult_wioa.date_of_program_entry_wioa = wagner.date_of_program_entry_wioa
order by adult_wioa.date_of_program_entry_wioa;

*/

/*


WITH wagner AS (
  SELECT
      p.social_security_number,
      p.wagner_peyser_employment_service_wioa,
      p.date_of_program_entry_wioa,
      p.date_of_program_exit_wioa,
      p.type_of_training_service_1_wioa AS wagner_train1,
      p.type_of_training_service_2_wioa AS wagner_train2,
      p.type_of_training_service_1_wioa AS wagner_train3,
      CAST('wagner_peyser' AS varchar) AS program2,
      ROW_NUMBER() OVER (
        PARTITION BY p.social_security_number
        ORDER BY p.date_of_program_entry_wioa ASC
      ) AS rn
  FROM ds_ar_dws.pirl_update p
  WHERE p.sheetnameproperty = 'Wagner-Peyser'
    AND p.wagner_peyser_employment_service_wioa = '1'
),
adult_wioa AS (
  SELECT
      p.social_security_number,
      p.date_of_program_entry_wioa,
      p.date_of_program_exit_wioa,
      p.type_of_training_service_1_wioa AS aw_train1,
      p.type_of_training_service_2_wioa AS aw_train2,
      p.type_of_training_service_1_wioa AS aw_train3,
      CAST('adult wioa' AS varchar) AS program1,
      ROW_NUMBER() OVER (
        PARTITION BY p.social_security_number
        ORDER BY p.date_of_program_entry_wioa ASC
      ) AS rn
  FROM ds_ar_dws.pirl_update p
  WHERE p.sheetnameproperty = 'Adult'
    AND p.adult_wioa IN (1,2,3)
)

SELECT
  a.social_security_number,
  a.date_of_program_entry_wioa,
  a.date_of_program_exit_wioa,
  a.program1,
  w.program2,
  CASE
    WHEN w.program2 = 'wagner_peyser' AND a.program1 IS NOT NULL THEN 'dual enrolled'
    WHEN w.program2 IS NULL AND a.program1 = 'adult wioa' THEN 'adult wioa only'
    WHEN w.program2 = 'wagner_peyser' AND a.program1 IS NULL THEN 'wagner peyser only'
  END AS dualenroll
FROM (SELECT * FROM adult_wioa QUALIFY rn = 1) a
FULL OUTER JOIN (SELECT * FROM wagner QUALIFY rn = 1) w
  ON a.social_security_number = w.social_security_number
-- (optional) if you *also* want the earliest dates to match exactly, add:
 AND a.date_of_program_entry_wioa = w.date_of_program_entry_wioa
ORDER BY COALESCE(a.date_of_program_entry_wioa, w.date_of_program_entry_wioa);
*/


