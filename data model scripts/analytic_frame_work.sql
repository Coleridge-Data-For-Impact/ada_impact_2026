SELECT
    COUNT(CASE WHEN cpc.social_security_number  IS NULL THEN 1 END)    AS null_count,
    COUNT(CASE WHEN cpc.social_security_number  IS NOT NULL THEN 1 END) AS not_null_count
FROM tr_state_impact_ada_training.ci_promis_cohort cpc ;

select *
from tr_state_impact_ada_training.ci_promis_cohort cpc 
limit 10;

select *
 from tr_state_impact_ada_training.dim_year_quarter dyq 
 where dyq.calendar_year = 2017


select *
 from tr_state_impact_ada_training.ci_promis_cohort cpc 
 left join tr_state_impact_ada_training.dim_person dp 
 	on cpc.ssn = dp.person_uid 
 join  tr_state_impact_ada_training.fact_person_ui_wage fpuw 
 	on dp.person_key = fpuw.person_key 
 join tr_state_impact_ada_training.dim_year_quarter dyq 
 	on fpuw.year_quarter_key = dyq.year_quarter_key 
 where dyq.quarter_start_date >= cpc.week_end_date 
 order by cpc.ssn , cpc.date_of_program_entry_wioa desc, fpuw.year_quarter_key 
 ;
 

select *
 from ds_ar_dws.promis p 
 where p.ssn = '0002f8722764e844f472be59eef70b64e4a2af06828e82282cda6014ec260606'
 
 ;
 
select min(cwc.date_of_program_entry_wioa)
from tr_state_impact_ada_training.ci_wioa_coenroll cwc 