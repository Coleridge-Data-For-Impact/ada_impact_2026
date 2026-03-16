/*
  This script will load the the FACT_Person_Program_Observation_Quarter table with data for the "Higher Education" program.
    Step 1
        Try to remove duplicated higher education records by grouping on ssn, entry quarter, and exit quarter and selecting
            the minium academic_year and miniumum term for each grouping.
        The entry and exit quarters are calculated using academic_year and term.  Academic_year has to be adjusted to calendar year. 
    Step 2
        Collect data for each record found in step 1.
        The results are returned in the cteHigherEducation CTE.
    Step 3
        Lookup the dimension keys for each cteHigherEducation record.
        The results are returned in the cteFactData CTE.
    Step 4
        The cteFactData is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Observation Quarter (Higher Education)
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
WITH cteDeDuplicate (social_security_number, Observation_Year_Quarter_Key, academic_year, academic_term, qtr_first_month, qtr_second_month, qtr_third_month)
AS
(
    SELECT  se.ssn_id AS social_security_number,
            obs_qtr.Year_Quarter_Key AS Observation_Year_Quarter_Key,
            MIN(se.academic_year),
            MIN(se.term) AS academic_term,
            MAX(CASE WHEN se.term IN ('3', '7') THEN 'No' ELSE 'Yes' END) AS first_month_qtr,
            CAST('Yes' AS CHAR(3)) AS second_month_qtr,
            MAX(CASE WHEN se.term IN ('0', '4') THEN 'No' ELSE 'Yes' END) AS third_month_qtr
    FROM ds_ar_dhe.student_enrollment_table se
    INNER JOIN DIM_Year_Quarter obs_qtr
        ON obs_qtr.calendar_year = CASE WHEN se.term IN ('1', '5') THEN CAST(CAST(se.academic_year AS INT) - 1 AS CHAR(4)) ELSE se.academic_year END
        AND obs_qtr.calendar_quarter = CASE WHEN se.term IN ('0', '4') THEN '3' WHEN se.term IN ('1', '5') THEN '4' WHEN se.term IN ('2', '6') THEN '1' WHEN se.term IN ('3', '7') THEN '2' END
    WHERE se.academic_year >= '2011'
    AND se.ssn_valid_format = 'Y'
    AND se.term IN ('0', '1', '2', '3', '4', '5', '6', '7')
    GROUP BY se.ssn_id, obs_qtr.Year_Quarter_Key
),
cteHigherEducation (social_security_number, program_name, Observation_Year_Quarter_Key, Enrolled_Entire_Quarter, Enrolled_First_Month_of_Quarter,
                    Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter, County_FIPS_Code, state_abbreviation, cip_code, cip_detail,
                    Participated_in_Postsecondary_Education_During_Program_Participation, Enrolled_in_Secondary_Education_Program,
                    Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  cteDeDuplicate.social_security_number,
            CAST('Higher Education' AS VARCHAR(75)) AS program_name,
            cteDeDuplicate.Observation_Year_Quarter_Key,
            CASE
                WHEN cteDeDuplicate.qtr_first_month = 'Yes' AND cteDeDuplicate.qtr_second_month = 'Yes' AND cteDeDuplicate.qtr_third_month = 'Yes' THEN 'Yes'
                ELSE 'No'
            END AS Enrolled_Entire_Quarter,
            cteDeDuplicate.qtr_first_month AS Enrolled_First_Month_of_Quarter,
            cteDeDuplicate.qtr_second_month AS Enrolled_Second_Month_of_Quarter,
            cteDeDuplicate.qtr_third_month AS Enrolled_Third_Month_of_Quarter,
            COALESCE(se.geo_county, '') AS County_FIPS_Code,
            COALESCE(se.geo_state, '') AS state_abbreviation,
            COALESCE(dfy.cip_code, '') AS cip_code,
            COALESCE(dfy.cip_detail, '') AS cip_detail,
            CAST('Yes' AS CHAR(3)) AS Participated_in_Postsecondary_Education_During_Program_Participation,
            CAST('Yes' AS CHAR(3)) AS Enrolled_in_Secondary_Education_Program,
            COALESCE(rsl.descr, '') AS Higher_Education_Student_Level,
            COALESCE(res.descr, '') AS Higher_Education_Enrollment_Status,
            COALESCE(rts.descr, '') AS Higher_Education_Tuition_Status
    FROM ds_ar_dhe.student_enrollment_table se
    INNER JOIN cteDeDuplicate
        ON se.ssn_id = cteDeDuplicate.social_security_number
        AND se.academic_year = cteDeDuplicate.academic_year
        and se.term = cteDeDuplicate.academic_term
    LEFT JOIN ds_ar_dhe.degree_fice_year_Table dfy
        ON se.fice_code = dfy.fice_code
        AND se.academic_year = dfy.academic_year
        AND se.major_1 = dfy.degree_code
    LEFT JOIN ds_ar_dhe.refenrollstatus res
        ON se.enroll_status = res.enrollstatusid
    LEFT JOIN ds_ar_dhe.refstudentlevel rsl
        ON se.student_level = rsl.countryid     -- note: The name of the PK for this table is probably a typo (i.e. incorrect)
    LEFT JOIN ds_ar_dhe.reftuitionstatus rts
        ON se.tuition_status = rts.tuitionstatusid
    WHERE se.academic_year >= '2011'
    AND se.ssn_valid_format = 'Y'
),
cteFactData (Person_Key, Program_Key, Observation_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key,
             Enrolled_Entire_Quarter, Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter,
             Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name,
             Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1,
             Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3,
             Participated_in_Postsecondary_Education_During_Program_Participation,  Received_Training_from_Private_Section_Operated_Program,
             Enrolled_in_Secondary_Education_Program, Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement,
             Youth_4th_Quarter_Placement, Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability,
             Zip_Code_of_Residence, Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
 AS
 (
     SELECT  --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = he.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = he.program_name
            ) AS Program_Key,
            --Observation Year Quarter Surrogate Key
            he.Observation_Year_Quarter_Key,
            --Lookup County Surrogate Key
            (
                SELECT DIM_County.County_Key
                FROM DIM_County
                WHERE DIM_County.County_FIPS_Code = he.County_FIPS_Code
            ) AS County_of_Residence_Key,
            --Lookup State Surrogate Key
            (
                SELECT DIM_State.State_Key
                FROM DIM_State
                WHERE DIM_State.State_Abbreviation = he.state_abbreviation
            ) AS State_of_Residence_Key,
            --Lookup CIP Surrogate Key
            (
                SELECT DIM_CIP.CIP_Key
                FROM DIM_CIP
                WHERE DIM_CIP.Classification_Code = CONCAT(he.cip_code, CONCAT(CAST('.' AS CHAR(1)), he.cip_detail))
            ) AS CIP_Classification_Key,
            --Measures
            he.Enrolled_Entire_Quarter,
            he.Enrolled_First_Month_of_Quarter,
            he.Enrolled_Second_Month_of_Quarter,
            he.Enrolled_Third_Month_of_Quarter,
            0 AS Gross_Monthly_Income,
            0 AS Net_Monthly_Income,
            CAST('9999-01-01' AS DATE) AS Date_of_Most_Recent_Career_Service,
            CAST('' AS CHAR(1)) AS Received_Training,
            CAST('' AS CHAR(1)) AS Eligible_Training_Provider_Name,
            CAST('' AS CHAR(1)) AS Eligible_Training_Provider_Program_of_Study,
            CAST('9999-01-01' AS DATE) AS Date_Entered_Training_1,
            CAST('' AS CHAR(1)) AS Type_of_Training_Service_1,
            CAST('9999-01-01' AS DATE) AS Date_Entered_Training_2,
            CAST('' AS CHAR(1)) AS Type_of_Training_Service_2,
            CAST('9999-01-01' AS DATE) AS Date_Entered_Training_3,
            CAST('' AS CHAR(1)) AS Type_of_Training_Service_3,
            he.Participated_in_Postsecondary_Education_During_Program_Participation,
            CAST('' AS CHAR(1)) AS Received_Training_from_Private_Section_Operated_Program,
            he.Enrolled_in_Secondary_Education_Program,
            CAST('9999-01-01' AS DATE) AS Date_Enrolled_in_Post_Exit_Education_or_Training_Program,
            CAST('' AS CHAR(1)) AS Youth_2nd_Quarter_Placement,
            CAST('' AS CHAR(1)) AS Youth_4th_Quarter_Placement,
            CAST('' AS CHAR(1)) AS Other_Reason_for_Exit,
            CAST('' AS CHAR(1)) AS Migrant_and_Seasonal_Farmworker_Status,
            CAST('' AS CHAR(1)) AS Individual_with_a_Disability,
            CAST('' AS CHAR(1)) AS Zip_Code_of_Residence,
            he.Higher_Education_Student_Level,
            he.Higher_Education_Enrollment_Status,
            he.Higher_Education_Tuition_Status
    FROM cteHigherEducation he
)
SELECT  COALESCE(Person_Key, 0),
        COALESCE(Program_Key, 0),
        COALESCE(Observation_Year_Quarter_Key, 0),
        COALESCE(County_of_Residence_Key, 0),
        COALESCE(State_of_Residence_Key, 0),
        COALESCE(CIP_Classification_Key, 0),
        Enrolled_Entire_Quarter,
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
FROM cteFactData;
