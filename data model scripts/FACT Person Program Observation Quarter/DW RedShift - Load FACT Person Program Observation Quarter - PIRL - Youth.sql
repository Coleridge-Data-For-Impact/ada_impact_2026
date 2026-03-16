/*
  This script will load the the FACT_Person_Program_Observation_Quarter table with data for the "Youth (WIOA)" program.
    Step 1
        The data is collected from the source table (ds_ar_dws.pirl) and returned in the ctePIRL comment table expression (CTE).
        Any reference values or boolean values are converted to text strings.
    Step 2
        The ctePirl data is then process in the cteFactData CTE which looks up the dimension keys.
    Step 3
        The cteFactData data is duplicated for each quarter in the range of entry_quarter and exit_quarter and returned in cteResults.
    Step 4
        The cteResults is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Observation Quarter (PIRL - youth)
INSERT INTO FACT_Person_Program_Observation_Quarter (Person_Key, Program_Key, Observation_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key,
                                                     CIP_Classification_Key, Enrolled_Entire_Quarter, Enrolled_First_Month_of_Quarter,
                                                     Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter, Gross_Monthly_Income, Net_Monthly_Income,
                                                     Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name,
                                                     Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1,
                                                     Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3,
                                                     Participated_in_Postsecondary_Education_During_Program_Participation, 
                                                     Received_Training_from_Private_Section_Operated_Program, Enrolled_in_Secondary_Education_Program, 
                                                     Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
                                                     Youth_4th_Quarter_Placement, Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status,
                                                     Individual_with_a_Disability, Zip_Code_of_Residence, Higher_Education_Student_Level,
                                                     Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
WITH ctePirl (social_security_number, program_name, entry_date, exit_date, County_FIPS_Code, state_abbreviation, cip_code,
              Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name, Eligible_Training_Provider_Program_of_Study,
              Date_Entered_Training_1, Type_of_Training_Service_1, Date_Entered_Training_2, Type_of_Training_Service_2,
              Date_Entered_Training_3, Type_of_Training_Service_3, Participated_in_Postsecondary_Education_During_Program_Participation,
              Received_Training_from_Private_Section_Operated_Program, Enrolled_in_Secondary_Education_Program,
              Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, Youth_4th_Quarter_Placement,
              Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability, Zip_Code_of_Residence)
AS
(
    SELECT  --LOOKUP VALUE FOR PERSON KEY
            social_security_number,
            --LOOKUP VALUE FOR PROGRAM KEY
            CAST('Youth (WIOA)' AS VARCHAR(75)) AS program_name,
            --LOOKUP VALUE FOR ENTRY YEAR QUARTER KEY
            date_of_program_entry_wioa as entry_date,
            --LOOKUP VALUE FOR EXIT YEAR QUARTER KEY
            COALESCE(date_of_program_exit_wioa, GETDATE()) AS exit_date,
            --LOOKUP VALUES FOR COUNTY KEY
            CASE
                WHEN LEN(RTRIM(county_code_of_residence)) = 3 AND states.State_FIPS_Code IS NOT NULL
                    THEN CAST(CONCAT(states.State_FIPS_Code, county_code_of_residence) AS VARCHAR(5))
                ELSE ''
            END AS County_FIPS_Code,
            --LOOKUP VALUE FOR STATE KEY
            COALESCE(state_code_of_residence_wioa, '') AS state_abbreviation,
            --LOOKUP VALUE FOR CIP KEY
            COALESCE(eligible_training_provider_cip_code_wioa, '') AS cip_code,
            --FACT MEASURES
            COALESCE(date_of_most_recent_career_service_wioa, CAST('9999-01-01' AS DATE)),
            CASE received_training_wioa
                WHEN '1' THEN 'Yes'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            COALESCE(eligible_training_provider_name_training_service_1_wioa, ''),
            CASE eligible_training_provider_program_of_study_by_potential_outcome
                WHEN '1' THEN 'A program of study leading to an industry-recognized certificate or certification'
                WHEN '2' THEN 'A program of study leading to a certificate of completion of a registered apprenticeship'
                WHEN '3' THEN 'A program of study leading to a license recognized by the State involved or the Federal Government'
                WHEN '4' THEN 'A program of study leading to an associate degree'
                WHEN '5' THEN 'A program of study leading to a baccalaureate degree'
                WHEN '6' THEN 'A program of study leading to a community college certificate of completion'
                WHEN '7' THEN 'A program of study leading to a secondary school diploma or its equivalent'
                WHEN '8' THEN 'A program of study leading to employment'
                WHEN '9' THEN 'A program of study leading to  a measurable skills gain'
                ELSE ''
            END,
            COALESCE(date_entered_training_1_wioa, CAST('9999-01-01' AS DATE)),
            CASE type_of_training_service_1_wioa
				WHEN '01' THEN 'On the Job Training (non-WIOA Youth).'
				WHEN '02' THEN 'Skill Upgrading'
				WHEN '03' THEN 'Entrepreneurial Training (non-WIOA Youth)'
				WHEN '04' THEN 'ABE or ESL (contextualized or other) in conjunction with Training'
				WHEN '05' THEN 'Customized Training'
				WHEN '06' THEN 'Occupational Skills Training (non-WIOA Youth)'
				WHEN '07' THEN 'ABE or ESL NOT in conjunction with training (funded by Trade Adjustment Assistance only)'
				WHEN '08' THEN 'Prerequisite Training'
				WHEN '09' THEN 'Registered Apprenticeship'
				WHEN '10' THEN 'Youth Occupational Skills Training'
				WHEN '11' THEN 'Other Non-Occupational-Skills Training'
				WHEN '12' THEN 'Job Readiness Training in conjunction with other training'
				WHEN '00' THEN 'No Training Service'
                ELSE ''
            END,
            COALESCE(date_entered_training_2, CAST('9999-01-01' AS DATE)),
            CASE type_of_training_service_2_wioa
				WHEN '01' THEN 'On the Job Training (non-WIOA Youth).'
				WHEN '02' THEN 'Skill Upgrading'
				WHEN '03' THEN 'Entrepreneurial Training (non-WIOA Youth)'
				WHEN '04' THEN 'ABE or ESL (contextualized or other) in conjunction with Training'
				WHEN '05' THEN 'Customized Training'
				WHEN '06' THEN 'Occupational Skills Training (non-WIOA Youth)'
				WHEN '07' THEN 'ABE or ESL NOT in conjunction with training (funded by Trade Adjustment Assistance only)'
				WHEN '08' THEN 'Prerequisite Training'
				WHEN '09' THEN 'Registered Apprenticeship'
				WHEN '10' THEN 'Youth Occupational Skills Training'
				WHEN '11' THEN 'Other Non-Occupational-Skills Training'
				WHEN '12' THEN 'Job Readiness Training in conjunction with other training'
				WHEN '00' THEN 'No Training Service'
                ELSE ''
            END,
            COALESCE(date_entered_training_3, CAST('9999-01-01' AS DATE)),
            CASE type_of_training_service_3_wioa
				WHEN '01' THEN 'On the Job Training (non-WIOA Youth).'
				WHEN '02' THEN 'Skill Upgrading'
				WHEN '03' THEN 'Entrepreneurial Training (non-WIOA Youth)'
				WHEN '04' THEN 'ABE or ESL (contextualized or other) in conjunction with Training'
				WHEN '05' THEN 'Customized Training'
				WHEN '06' THEN 'Occupational Skills Training (non-WIOA Youth)'
				WHEN '07' THEN 'ABE or ESL NOT in conjunction with training (funded by Trade Adjustment Assistance only)'
				WHEN '08' THEN 'Prerequisite Training'
				WHEN '09' THEN 'Registered Apprenticeship'
				WHEN '10' THEN 'Youth Occupational Skills Training'
				WHEN '11' THEN 'Other Non-Occupational-Skills Training'
				WHEN '12' THEN 'Job Readiness Training in conjunction with other training'
				WHEN '00' THEN 'No Training Service'
                ELSE ''
            END,
            CASE participated_in_postsecondary_education_during_program_participation_wioa
                WHEN '1' THEN 'Yes'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            CASE received_training_from_programs_operated_by_the_private_sector
                WHEN '1' THEN 'Yes'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            CASE enrolled_in_secondary_education_program_wioa
                WHEN '1' THEN 'Yes'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            COALESCE(date_enrolled_in_post_exit_education_or_training_program_leading_to_a_recognized_postsecondary_credential_wioa, CAST('9999-01-01' AS DATE)),
            CASE youth_2nd_quarter_placement_title_i_wioa
                WHEN '1' THEN 'Occupational Skills Training'
                WHEN '2' THEN 'Postsecondary Education'
                WHEN '3' THEN 'Secondary Education'
                WHEN '0' THEN 'No placement'
                ELSE ''
            END,
            CASE youth_4th_quarter_placement_title_i_wioa
                WHEN '1' THEN 'Occupational Skills Training'
                WHEN '2' THEN 'Postsecondary Education'
                WHEN '3' THEN 'Secondary Education'
                WHEN '0' THEN 'No placement'
                ELSE ''
            END,
            CASE other_reasons_for_exit_wioa
                WHEN '01' THEN 'Institutionalized'
                WHEN '02' THEN 'Health/Medical'
                WHEN '03' THEN 'Deceased'
                WHEN '05' THEN 'Foster Care'
                WHEN '06' THEN 'Ineligible'
                WHEN '07' THEN 'Criminal Offender'
                WHEN '00' THEN 'No'
                ELSE ''
            END,
            CASE migrant_and_seasonal_farmworker_status
                WHEN '1' THEN 'Seasonal Farmworker Adult'
                WHEN '2' THEN 'Migrant Farmworker Adult'
                WHEN '3' THEN 'MSFW Youth'
                WHEN '4' THEN 'Dependent Adult'
                WHEN '5' THEN 'Dependent Youth'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            CASE individual_with_a_disability_wioa
                WHEN '1' THEN 'Yes'
                WHEN '0' THEN 'No'
                ELSE ''
            END,
            COALESCE(zip_code_of_residence, '')
    FROM ds_ar_dws.pirl
    LEFT JOIN DIM_State states
        ON pirl.state_code_of_residence_wioa = states.state_abbreviation
    WHERE DATEPART(year, date_of_program_entry_wioa) >= 2010
    AND valid_ssn_format = 'Y'
    AND youth_wioa IN (1, 2, 3)
),
cteFactData (Person_Key, Program_Key, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key,
             Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name,
             Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1,
             Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
             Participated_in_Postsecondary_Education_During_Program_Participation, Received_Training_from_Private_Section_Operated_Program,
             Enrolled_in_Secondary_Education_Program, Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
             Youth_4th_Quarter_Placement,  Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability,
             Zip_Code_of_Residence, Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status,
             entry_date, exit_date)
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
            --Lookup Entry Year Quarter Surrogate Key
            (
                SELECT entry_qtr.Year_Quarter_Key
                FROM DIM_Year_Quarter entry_qtr
                WHERE pirl.entry_date BETWEEN entry_qtr.quarter_start_date AND entry_qtr.quarter_end_date      
            ) AS Entry_Year_Quarter_Key,
            --Lookup Exit Year Quarter Surrogate Key
            (
                SELECT exit_qtr.Year_Quarter_Key
                FROM DIM_Year_Quarter exit_qtr
                WHERE pirl.exit_date BETWEEN exit_qtr.quarter_start_date and exit_qtr.quarter_end_date
            ) AS Exit_Year_Quarter_Key,
            --Lookup County Surrogate Key
            (
                SELECT DIM_County.County_Key
                FROM DIM_County
                WHERE DIM_County.County_FIPS_Code = pirl.County_FIPS_Code
            ) AS County_of_Residence_Key,
            --Lookup State Surrogate Key
            (
                SELECT DIM_State.State_Key
                FROM DIM_State
                WHERE DIM_State.State_Abbreviation = pirl.state_abbreviation
            ) AS State_of_Residence_Key,
            --Lookup CIP Surrogate Key
            (
                SELECT DIM_CIP.CIP_Key
                FROM DIM_CIP
                WHERE DIM_CIP.Classification_Code = pirl.cip_code
            ) AS CIP_Classification_Key,
            --Measures
            0 AS Gross_Monthly_Income,
            0 AS Net_Monthly_Income,
            pirl.Date_of_Most_Recent_Career_Service,
            pirl.Received_Training,
            pirl.Eligible_Training_Provider_Name,
            pirl.Eligible_Training_Provider_Program_of_Study,
            pirl.Date_Entered_Training_1,
            pirl.Type_of_Training_Service_1,
            pirl.Date_Entered_Training_2,
            pirl.Type_of_Training_Service_2,
            pirl.Date_Entered_Training_3,
            pirl.Type_of_Training_Service_3,
            pirl.Participated_in_Postsecondary_Education_During_Program_Participation,
            pirl.Received_Training_from_Private_Section_Operated_Program,
            pirl.Enrolled_in_Secondary_Education_Program,
            pirl.Date_Enrolled_in_Post_Exit_Education_or_Training_Program,
            pirl.Youth_2nd_Quarter_Placement,
            pirl.Youth_4th_Quarter_Placement,
            pirl.Other_Reason_for_Exit,
            pirl.Migrant_and_Seasonal_Farmworker_Status,
            pirl.Individual_with_a_Disability,
            pirl.Zip_Code_of_Residence,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Student_Level,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Enrollment_Status,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Tuition_Status,
            entry_date,
            exit_date
    FROM ctePirl pirl
),
cteResults (Person_Key, Program_Key, Observation_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key,
            Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter, Gross_Monthly_Income, Net_Monthly_Income,
            Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name, Eligible_Training_Provider_Program_of_Study,
            Date_Entered_Training_1, Type_of_Training_Service_1, Date_Entered_Training_2, Type_of_Training_Service_2,
            Date_Entered_Training_3, Type_of_Training_Service_3, Participated_in_Postsecondary_Education_During_Program_Participation, 
            Received_Training_from_Private_Section_Operated_Program, Enrolled_in_Secondary_Education_Program, 
            Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, Youth_4th_Quarter_Placement,
            Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability, Zip_Code_of_Residence,
            Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  COALESCE(Person_Key, 0),
            COALESCE(Program_Key, 0),
            qtr.Year_Quarter_Key AS Observation_Year_Quarter_Key,
            COALESCE(County_of_Residence_Key, 0),
            COALESCE(State_of_Residence_Key, 0),
            COALESCE(CIP_Classification_Key, 0),
            CASE
                WHEN qtr.Year_Quarter_Key = cteFactData.Entry_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.entry_date) NOT IN (1, 4, 7, 10) THEN 'No'
                WHEN qtr.Year_Quarter_Key = cteFactData.Exit_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.exit_date) NOT IN (1, 4, 7, 10) THEN 'No'
                ELSE 'Yes'
            END AS Enrolled_First_Month_of_Quarter,
            CASE
                WHEN qtr.Year_Quarter_Key = cteFactData.Entry_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.entry_date) NOT IN (2, 5, 8, 11) THEN 'No'
                WHEN qtr.Year_Quarter_Key = cteFactData.Exit_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.exit_date) NOT IN (2, 5, 8, 11) THEN 'No'
                ELSE 'Yes'
            END AS Enrolled_Second_Month_of_Quarter,
            CASE
                WHEN qtr.Year_Quarter_Key = cteFactData.Entry_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.entry_date) NOT IN (3, 6, 9, 12) THEN 'No'
                WHEN qtr.Year_Quarter_Key = cteFactData.Exit_Year_Quarter_Key AND DATEPART(MONTH, cteFactData.exit_date) NOT IN (3, 6, 9, 12) THEN 'No'
                ELSE 'Yes'
            END AS Enrolled_Third_Month_of_Quarter,
            Gross_Monthly_Income,
            Net_Monthly_Income,
            Date_of_Most_Recent_Career_Service,
            Received_Training,
            Eligible_Training_Provider_Name,
            Eligible_Training_Provider_Program_of_Study,
            Date_Entered_Training_1,
            Type_of_Training_Service_1,
            Date_Entered_Training_2,
            Type_of_Training_Service_2,
            Date_Entered_Training_3,
            Type_of_Training_Service_3,
            Participated_in_Postsecondary_Education_During_Program_Participation,
            Received_Training_from_Private_Section_Operated_Program,
            Enrolled_in_Secondary_Education_Program,
            Date_Enrolled_in_Post_Exit_Education_or_Training_Program,
            Youth_2nd_Quarter_Placement,
            Youth_4th_Quarter_Placement,
            Other_Reason_for_Exit,
            Migrant_and_Seasonal_Farmworker_Status,
            Individual_with_a_Disability,
            Zip_Code_of_Residence,
            Higher_Education_Student_Level,
            Higher_Education_Enrollment_Status,
            Higher_Education_Tuition_Status
    FROM cteFactData
    INNER JOIN DIM_Year_Quarter qtr
        ON qtr.Year_Quarter_Key BETWEEN cteFactData.Entry_Year_Quarter_Key AND cteFactData.Exit_Year_Quarter_Key
)
SELECT  COALESCE(Person_Key, 0),
        COALESCE(Program_Key, 0),
        Observation_Year_Quarter_Key,
        COALESCE(County_of_Residence_Key, 0),
        COALESCE(State_of_Residence_Key, 0),
        COALESCE(CIP_Classification_Key, 0),
        CASE
            WHEN Enrolled_First_Month_of_Quarter = 'Yes' AND Enrolled_Second_Month_of_Quarter = 'Yes' AND Enrolled_Third_Month_of_Quarter = 'Yes' THEN 'Yes'
            ELSE 'No'
        END AS Enrolled_Entire_Quarter,
        Enrolled_First_Month_of_Quarter,
        Enrolled_Second_Month_of_Quarter,
        Enrolled_Third_Month_of_Quarter,
        Gross_Monthly_Income,
        Net_Monthly_Income,
        Date_of_Most_Recent_Career_Service,
        Received_Training,
        Eligible_Training_Provider_Name,
        Eligible_Training_Provider_Program_of_Study,
        Date_Entered_Training_1,
        Type_of_Training_Service_1,
        Date_Entered_Training_2,
        Type_of_Training_Service_2,
        Date_Entered_Training_3,
        Type_of_Training_Service_3,
        Participated_in_Postsecondary_Education_During_Program_Participation,
        Received_Training_from_Private_Section_Operated_Program,
        Enrolled_in_Secondary_Education_Program,
        Date_Enrolled_in_Post_Exit_Education_or_Training_Program,
        Youth_2nd_Quarter_Placement,
        Youth_4th_Quarter_Placement,
        Other_Reason_for_Exit,
        Migrant_and_Seasonal_Farmworker_Status,
        Individual_with_a_Disability,
        Zip_Code_of_Residence,
        Higher_Education_Student_Level,
        Higher_Education_Enrollment_Status,
        Higher_Education_Tuition_Status
FROM cteResults;
