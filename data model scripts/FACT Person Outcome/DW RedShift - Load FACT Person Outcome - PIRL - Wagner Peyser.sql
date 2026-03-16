/*
  This script will load the the FACT_Person_Program_Outcome table with data for the "Wagner-Peyser Employment Service (WIOA)" program.
  Step 1
    The data is collected from the source table (ds_ar_dws.pirl) and returned in the ctePIRL comment table expression (CTE).
    Any reference values or boolean values are converted to text strings.
  Step 2
    The ctePirl data is then process thru the cteFactData CTE which looks up the dimension keys.
  Step 3
    The cteFactData is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Outcome (PIRL - Wagner Peyser)
INSERT INTO FACT_Person_Program_Outcome (Person_Key, Program_Key, Exit_Year_Quarter_Key, Employed_in_1st_Quarter_After_Exit_Quarter,
                                         Type_of_Employment_Match_1st_Quarter_After_Exit_Quarter, Earnings_1st_Quarter_After_Exit_Quarter,
                                         Employed_in_2nd_Quarter_After_Exit_Quarter, Type_of_Employment_Match_2nd_Quarter_After_Exit_Quarter,
                                         Earnings_2nd_Quarter_After_Exit_Quarter, Employed_in_3rd_Quarter_After_Exit_Quarter,
                                         Type_of_Employment_Match_3rd_Quarter_After_Exit_Quarter, Earnings_3rd_Quarter_After_Exit_Quarter,
                                         Employed_in_4th_Quarter_After_Exit_Quarter, Type_of_Employment_Match_4th_Quarter_After_Exit_Quarter,
                                         Earnings_4th_Quarter_After_Exit_Quarter, Employment_Related_to_Training,
                                         Retention_with_Same_Employer_2nd_Quarter_and_4th_Quarter, Type_of_Recognized_Credential_1,
                                         Type_of_Recognized_Credential_2, Type_of_Recognized_Credential_3, Date_Attained_Recognized_Credential_1,
                                         Date_Attained_Recognized_Credential_2, Date_Attained_Recognized_Credential_3,
                                         Date_of_Most_Recent_Measurable_Skill_Gain_Educational_Functional_Level,
                                         Date_of_Most_Recent_Measurable_Skill_Gain_Postsecondary_Transcript,
                                         Date_of_Most_Recent_Measurable_Skill_Gain_Secondary_Transcript,
                                         Date_of_Most_Recent_Measurable_Skill_Gain_Training_Milestone,
                                         Date_of_Most_Recent_Measurable_Skill_Gain_Skills_Progression,
                                         Date_Enrolled_in_Education_or_Training_Program_Leading_to_Credential_or_Employment,
                                         Date_Completed_an_Education_or_Training_Program_Leading_to_Credential_or_Employment,
                                         Date_Attained_Graduate_or_Post_Graduate_Degree)
WITH ctePirl (social_security_number, program_name, exit_date, Employed_in_1st_Quarter_After_Exit_Quarter,
              Type_of_Employment_Match_1st_Quarter_After_Exit_Quarter, Earnings_1st_Quarter_After_Exit_Quarter,
              Employed_in_2nd_Quarter_After_Exit_Quarter, Type_of_Employment_Match_2nd_Quarter_After_Exit_Quarter,
              Earnings_2nd_Quarter_After_Exit_Quarter, Employed_in_3rd_Quarter_After_Exit_Quarter,
              Type_of_Employment_Match_3rd_Quarter_After_Exit_Quarter, Earnings_3rd_Quarter_After_Exit_Quarter,
              Employed_in_4th_Quarter_After_Exit_Quarter, Type_of_Employment_Match_4th_Quarter_After_Exit_Quarter,
              Earnings_4th_Quarter_After_Exit_Quarter, Employment_Related_to_Training,
              Retention_with_Same_Employer_2nd_Quarter_and_4th_Quarter, Type_of_Recognized_Credential_1,
              Type_of_Recognized_Credential_2, Type_of_Recognized_Credential_3, Date_Attained_Recognized_Credential_1,
              Date_Attained_Recognized_Credential_2, Date_Attained_Recognized_Credential_3,
              Date_of_Most_Recent_Measurable_Skill_Gain_Educational_Functional_Level,
              Date_of_Most_Recent_Measurable_Skill_Gain_Postsecondary_Transcript,
              Date_of_Most_Recent_Measurable_Skill_Gain_Secondary_Transcript,
              Date_of_Most_Recent_Measurable_Skill_Gain_Training_Milestone,
              Date_of_Most_Recent_Measurable_Skill_Gain_Skills_Progression,
              Date_Enrolled_in_Education_or_Training_Program_Leading_to_Credential_or_Employment,
              Date_Completed_an_Education_or_Training_Program_Leading_to_Credential_or_Employment,
              Date_Attained_Graduate_or_Post_Graduate_Degree)
AS
(
    SELECT  social_security_number,
            CAST('Wagner-Peyser Employment Service (WIOA)' AS VARCHAR(75)) AS program_name,
            date_of_program_exit_wioa,
            CASE
                WHEN employed_in_1st_quarter_after_exit_quarter_wioa IN (1, 2, 3) THEN 'Yes'
                ELSE 'No'
            END,
            CASE type_of_employment_match_1st_quarter_after_exit_quarter_wioa
                WHEN 1 THEN 'UI Wage Data'
                WHEN 2 THEN 'Federal Employment Records (OPM, USPS)'
                WHEN 3 THEN 'Military Employment Records (DOD)'
                WHEN 4 THEN 'Non UI verification'
                WHEN 5 THEN 'Information not yet available'
                WHEN 0 THEN 'Not employed'
                ELSE ''
            END,
            COALESCE(earnings_1st_quarter_after_exit_quarter_wioa, 0),
            CASE
                WHEN employed_in_2nd_quarter_after_exit_quarter_wioa IN (1, 2, 3) THEN 'Yes'
                ELSE 'No'
            END,
            CASE type_of_employment_match_2nd_quarter_after_exit_quarter_wioa
                WHEN 1 THEN 'UI Wage Data'
                WHEN 2 THEN 'Federal Employment Records (OPM, USPS)'
                WHEN 3 THEN 'Military Employment Records (DOD)'
                WHEN 4 THEN 'Non UI verification'
                WHEN 5 THEN 'Information not yet available'
                WHEN 0 THEN 'Not employed'
                ELSE ''
            END,
            COALESCE(earnings_2nd_quarter_after_exit_quarter_wioa, 0),
            CASE
                WHEN employed_in_3rd_quarter_after_exit_quarter_wioa IN (1, 2, 3) THEN 'Yes'
                ELSE 'No'
            END,
            CASE type_of_employment_match_3rd_quarter_after_exit_quarter_wioa
                WHEN 1 THEN 'UI Wage Data'
                WHEN 2 THEN 'Federal Employment Records (OPM, USPS)'
                WHEN 3 THEN 'Military Employment Records (DOD)'
                WHEN 4 THEN 'Non UI verification'
                WHEN 5 THEN 'Information not yet available'
                WHEN 0 THEN 'Not employed'
                ELSE ''
            END,
            COALESCE(earnings_3rd_quarter_after_exit_quarter_wioa, 0),
            CASE
                WHEN employed_in_4th_quarter_after_exit_quarter_wioa IN (1, 2, 3) THEN 'Yes'
                ELSE 'No'
            END,
            CASE type_of_employment_match_4th_quarter_after_exit_quarter_wioa
                WHEN 1 THEN 'UI Wage Data'
                WHEN 2 THEN 'Federal Employment Records (OPM, USPS)'
                WHEN 3 THEN 'Military Employment Records (DOD)'
                WHEN 4 THEN 'Non UI verification'
                WHEN 5 THEN 'Information not yet available'
                WHEN 0 THEN 'Not employed'
                ELSE ''
            END,
            COALESCE(earnings_4th_quarter_after_exit_quarter_wioa, 0),
            CASE employment_related_to_training_2nd_quarter_after_exit_wioa
                WHEN 1 THEN 'Yes'
                WHEN 0 THEN 'No'
                ELSE ''
            END,
            CASE retention_with_the_same_employer_in_the_2nd_quarter_and_the_4th_quarter_wioa
                WHEN 1 THEN 'Yes'
                WHEN 0 THEN 'No'
                ELSE ''
            END,
            CASE type_of_recognized_credential_wioa
                WHEN 1 THEN 'Secondary School Diploma/or equivalency'
                WHEN 2 THEN 'AA or AS Diploma/Degree'
                WHEN 3 THEN 'BA or BS Diploma/Degree'
                WHEN 4 THEN 'Occupational Licensure'
                WHEN 5 THEN 'Occupational Certificate'
                WHEN 6 THEN 'Occupational Certification'
                WHEN 7 THEN 'Other Recognized Diploma, Degree, or Certificate'
                WHEN 0 THEN 'No recognized credential'
                ELSE ''
            END,
            CASE type_of_recognized_credential_2_wioa
                WHEN 1 THEN 'Secondary School Diploma/or equivalency'
                WHEN 2 THEN 'AA or AS Diploma/Degree'
                WHEN 3 THEN 'BA or BS Diploma/Degree'
                WHEN 4 THEN 'Occupational Licensure'
                WHEN 5 THEN 'Occupational Certificate'
                WHEN 6 THEN 'Occupational Certification'
                WHEN 7 THEN 'Other Recognized Diploma, Degree, or Certificate'
                WHEN 0 THEN 'No recognized credential'
                ELSE ''
            END,
            CASE type_of_recognized_credential_3_wioa
                WHEN 1 THEN 'Secondary School Diploma/or equivalency'
                WHEN 2 THEN 'AA or AS Diploma/Degree'
                WHEN 3 THEN 'BA or BS Diploma/Degree'
                WHEN 4 THEN 'Occupational Licensure'
                WHEN 5 THEN 'Occupational Certificate'
                WHEN 6 THEN 'Occupational Certification'
                WHEN 7 THEN 'Other Recognized Diploma, Degree, or Certificate'
                WHEN 0 THEN 'No recognized credential'
                ELSE ''
            END,
            COALESCE(date_attained_recognized_credential_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_attained_recognized_credential_2_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_attained_recognized_credential_3_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_of_most_recent_measurable_skill_gains_educational_functioning_level_efl_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_of_most_recent_measurable_skill_gains_postsecondary_transcript_report_card_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_of_most_recent_measurable_skill_gains_secondary_transcript_report_card_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_of_most_recent_measurable_skill_gains_training_milestone_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_of_most_recent_measurable_skill_gains_skills_progression_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_enrolled_in_post_exit_education_or_training_program_leading_to_a_recognized_postsecondary_credential_wioa, CAST('9999-01-01' AS DATE)),
            COALESCE(date_completed_during_program_participation_an_education_or_training_program_leading_to_a_recognized_credential_or_employment, CAST('9999-01-01' AS DATE)),
            COALESCE(date_attained_graduate_post_graduate_degree_wioa, CAST('9999-01-01' AS DATE))
    FROM ds_ar_dws.pirl_update
    WHERE DATEPART(year, date_of_program_exit_wioa) >= 2010
    AND valid_ssn_format = 'Y'
    AND pirl_update.wagner_peyser_employment_service_wioa = 1
    AND sheetnameproperty = 'Wagner-Peyser'
),
cteFactData
AS
(
    SELECT  --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = pirl.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = pirl.program_name
            ) AS Program_Key,
            --Lookup Exit Year Quarter Surrogate Key
            (
                SELECT exit_qtr.Year_Quarter_Key
                FROM DIM_Year_Quarter exit_qtr
                WHERE pirl.exit_date between exit_qtr.quarter_start_date and exit_qtr.quarter_end_date
            ) AS Exit_Year_Quarter_Key,
            pirl.Employed_in_1st_Quarter_After_Exit_Quarter,
            pirl.Type_of_Employment_Match_1st_Quarter_After_Exit_Quarter,
            pirl.Earnings_1st_Quarter_After_Exit_Quarter,
            pirl.Employed_in_2nd_Quarter_After_Exit_Quarter,
            pirl.Type_of_Employment_Match_2nd_Quarter_After_Exit_Quarter,
            pirl.Earnings_2nd_Quarter_After_Exit_Quarter,
            pirl.Employed_in_3rd_Quarter_After_Exit_Quarter,
            pirl.Type_of_Employment_Match_3rd_Quarter_After_Exit_Quarter,
            pirl.Earnings_3rd_Quarter_After_Exit_Quarter,
            pirl.Employed_in_4th_Quarter_After_Exit_Quarter,
            pirl.Type_of_Employment_Match_4th_Quarter_After_Exit_Quarter,
            pirl.Earnings_4th_Quarter_After_Exit_Quarter,
            pirl.Employment_Related_to_Training,
            pirl.Retention_with_Same_Employer_2nd_Quarter_and_4th_Quarter,
            pirl.Type_of_Recognized_Credential_1,
            pirl.Type_of_Recognized_Credential_2,
            pirl.Type_of_Recognized_Credential_3,
            pirl.Date_Attained_Recognized_Credential_1,
            pirl.Date_Attained_Recognized_Credential_2,
            pirl.Date_Attained_Recognized_Credential_3,
            pirl.Date_of_Most_Recent_Measurable_Skill_Gain_Educational_Functional_Level,
            pirl.Date_of_Most_Recent_Measurable_Skill_Gain_Postsecondary_Transcript,
            pirl.Date_of_Most_Recent_Measurable_Skill_Gain_Secondary_Transcript,
            pirl.Date_of_Most_Recent_Measurable_Skill_Gain_Training_Milestone,
            pirl.Date_of_Most_Recent_Measurable_Skill_Gain_Skills_Progression,
            pirl.Date_Enrolled_in_Education_or_Training_Program_Leading_to_Credential_or_Employment,
            pirl.Date_Completed_an_Education_or_Training_Program_Leading_to_Credential_or_Employment,
            pirl.Date_Attained_Graduate_or_Post_Graduate_Degree
    FROM ctePirl pirl
)
SELECT DISTINCT
        COALESCE(Person_Key, 0),
        COALESCE(Program_Key, 0),
        COALESCE(Exit_Year_Quarter_Key, 0),
        Employed_in_1st_Quarter_After_Exit_Quarter,
        Type_of_Employment_Match_1st_Quarter_After_Exit_Quarter, Earnings_1st_Quarter_After_Exit_Quarter,
        Employed_in_2nd_Quarter_After_Exit_Quarter, Type_of_Employment_Match_2nd_Quarter_After_Exit_Quarter,
        Earnings_2nd_Quarter_After_Exit_Quarter, Employed_in_3rd_Quarter_After_Exit_Quarter,
        Type_of_Employment_Match_3rd_Quarter_After_Exit_Quarter, Earnings_3rd_Quarter_After_Exit_Quarter,
        Employed_in_4th_Quarter_After_Exit_Quarter, Type_of_Employment_Match_4th_Quarter_After_Exit_Quarter,
        Earnings_4th_Quarter_After_Exit_Quarter, Employment_Related_to_Training,
        Retention_with_Same_Employer_2nd_Quarter_and_4th_Quarter, Type_of_Recognized_Credential_1,
        Type_of_Recognized_Credential_2, Type_of_Recognized_Credential_3, Date_Attained_Recognized_Credential_1,
        Date_Attained_Recognized_Credential_2, Date_Attained_Recognized_Credential_3,
        Date_of_Most_Recent_Measurable_Skill_Gain_Educational_Functional_Level,
        Date_of_Most_Recent_Measurable_Skill_Gain_Postsecondary_Transcript,
        Date_of_Most_Recent_Measurable_Skill_Gain_Secondary_Transcript,
        Date_of_Most_Recent_Measurable_Skill_Gain_Training_Milestone,
        Date_of_Most_Recent_Measurable_Skill_Gain_Skills_Progression,
        Date_Enrolled_in_Education_or_Training_Program_Leading_to_Credential_or_Employment,
        Date_Completed_an_Education_or_Training_Program_Leading_to_Credential_or_Employment,
        Date_Attained_Graduate_or_Post_Graduate_Degree
FROM cteFactData;
