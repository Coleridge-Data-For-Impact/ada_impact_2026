/*
  This script will load the the FACT_Person_Program_Participation table with data for the "Higher Education" program.
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

-- FACT Person Program Participation (Higher Education)
INSERT INTO FACT_Person_Program_Participation (Person_Key, Intake_Characteristics_Key, Program_Key, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key,
                                               County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key, Gross_Monthly_Income, 
                                               Net_Monthly_Income, Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name, 
                                               Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1, 
                                               Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
                                               Participated_in_Postsecondary_Education_During_Program_Participation, 
                                               Received_Training_from_Private_Section_Operated_Program, Enrolled_in_Secondary_Education_Program, 
                                               Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
                                               Youth_4th_Quarter_Placement, Incarcerated_at_Program_Entry, Date_Released_from_Incarceration, 
                                               Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability,
                                               Zip_Code_of_Residence, Higher_Education_Student_Level, Higher_Education_Enrollment_Status, 
                                               Higher_Education_Tuition_Status)
WITH cteDeDuplicate (social_security_number, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key, academic_year, academic_term)
AS
(
    SELECT  se.ssn_id AS social_security_number,
            entry_qtr.Year_Quarter_Key AS Entry_Year_Quarter_Key,
            exit_qtr.Year_Quarter_Key AS Exit_Year_Quarter_Key,
            MIN(se.academic_year),
            MIN(se.term) AS academic_term
    FROM ds_ar_dhe.student_enrollment_table se
    INNER JOIN DIM_Year_Quarter entry_qtr
        ON entry_qtr.calendar_year = CASE WHEN se.term IN ('1', '5') THEN CAST(CAST(se.academic_year AS INT) - 1 AS CHAR(4)) ELSE se.academic_year END
        AND entry_qtr.calendar_quarter = CASE WHEN se.term IN ('0', '4') THEN '3' WHEN se.term IN ('1', '5') THEN '3' WHEN se.term IN ('2', '6') THEN '1' WHEN se.term IN ('3', '7') THEN '2' END
    INNER JOIN DIM_Year_Quarter exit_qtr
        ON exit_qtr.calendar_year = CASE WHEN se.term IN ('1', '5') THEN CAST(CAST(se.academic_year AS INT) - 1 AS CHAR(4)) ELSE se.academic_year END
        AND exit_qtr.calendar_quarter = CASE WHEN se.term IN ('0', '4') THEN '3' WHEN se.term IN ('1', '5') THEN '4' WHEN se.term IN ('2', '6') THEN '2' WHEN se.term IN ('3', '7') THEN '2' END
    WHERE se.academic_year >= '2011'
    AND se.ssn_valid_format = 'Y'
    AND se.term IN ('0', '1', '2', '3', '4', '5', '6', '7')
    GROUP BY se.ssn_id, entry_qtr.Year_Quarter_Key, exit_qtr.Year_Quarter_Key
),
cteHigherEducation (social_security_number, program_name, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key, County_FIPS_Code, state_abbreviation, cip_code, cip_detail,
                    Highest_School_Grade_Completed_at_Program_Entry, Highest_Education_Level_Completed_at_Program_Entry, School_Status_at_Program_Entry,
                    Employment_Status_at_Program_Entry, Long_Term_Unemployment_at_Program_Entry, Exhausting_TANF_Within_2_Yrs_at_Program_Entry,
                    Foster_Care_Youth_Status_at_Program_Entry, Homeless_or_Runaway_at_Program_Entry, Ex_Offender_Status_at_Program_Entry,
                    Low_Income_Status_at_Program_Entry, English_Language_Learner_at_Program_Entry, Low_Levels_of_Literacy_at_Program_Entry,
                    Cultural_Barriers_at_Program_Entry, Single_Parent_at_Program_Entry, Displaced_Homemaker_at_Program_Entry, 
                    Participated_in_Postsecondary_Education_During_Program_Participation, Enrolled_in_Secondary_Education_Program, 
                    Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  cteDeDuplicate.social_security_number,
            CAST('Higher Education' AS VARCHAR(75)) AS program_name,
            cteDeDuplicate.Entry_Year_Quarter_Key,
            cteDeDuplicate.Exit_Year_Quarter_Key,
            COALESCE(se.geo_county, '') AS County_FIPS_Code,
            COALESCE(se.geo_state, '') AS state_abbreviation,
            COALESCE(dfy.cip_code, '') AS cip_code,
            COALESCE(dfy.cip_detail, '') AS cip_detail,
            CASE
                WHEN se.student_level = '14' THEN '11'
                WHEN se.student_level = '13' THEN ''
                WHEN se.diploma_ged = 1 THEN ''
                ELSE '12'
            END AS Highest_School_Grade_Completed_at_Program_Entry,
            CASE 
                WHEN se.student_level IN ('02','03','04') THEN 'Completed one of more years of postsecondary education'
                WHEN se.student_level IN ('05', '06', '10') THEN 'Attained a Bachelor degree'
                WHEN se.student_level IN ('07', '08', '09') THEN 'Attained a degree beyond a Bachelor degree'
                WHEN se.student_level IN ('13', '14') THEN ''
                WHEN se.diploma_ged = 1 THEN 'Attained a secondary school equivalency'
                ELSE 'Attained secondary school diploma'
            END AS Highest_Education_Level_Completed_at_Program_Entry,
            CASE
                WHEN se.student_level IN ('13', '14') THEN 'In-school, secondary school or less'
                WHEN se.student_level BETWEEN '01' AND '11' THEN 'In-school, Postsecondary school'
                ELSE ''
            END AS School_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Employment_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Long_Term_Unemployment_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Exhausting_TANF_Within_2_Yrs_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Foster_Care_Youth_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Homeless_or_Runaway_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Ex_Offender_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Low_Income_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS English_Language_Learner_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Low_Levels_of_Literacy_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Cultural_Barriers_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Single_Parent_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Displaced_Homemaker_at_Program_Entry,
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
       ON se.student_level = rsl.studentlevelid     -- note: The name of the PK for this table is probably a typo (i.e. incorrect)
    LEFT JOIN ds_ar_dhe.reftuitionstatus rts
        ON se.tuition_status = rts.tuitionstatusid
    WHERE se.academic_year >= '2011'
    AND se.ssn_valid_format = 'Y'
),
cteFactData (Person_Key, Intake_Characteristics_Key, Program_Key, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key, County_of_Residence_Key,
             State_of_Residence_Key, CIP_Classification_Key, Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service,
             Received_Training, Eligible_Training_Provider_Name, Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1,
             Type_of_Training_Service_1, Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
             Participated_in_Postsecondary_Education_During_Program_Participation, Received_Training_from_Private_Section_Operated_Program,
             Enrolled_in_Secondary_Education_Program, Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
             Youth_4th_Quarter_Placement, Incarcerated_at_Program_Entry, Date_Released_from_Incarceration, Other_Reason_for_Exit,
             Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability, Zip_Code_of_Residence,
             Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = he.social_security_number
            ) AS Person_Key,
            --Lookup Intake Characteristics Surrogate Key
            (
                SELECT DIM_Intake_Characteristics.Intake_Characteristics_Key
                FROM DIM_Intake_Characteristics
                WHERE he.Highest_School_Grade_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_School_Grade_Completed_at_Program_Entry
                AND he.Highest_Education_Level_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_Education_Level_Completed_at_Program_Entry
                AND he.School_Status_at_Program_Entry = DIM_Intake_Characteristics.School_Status_at_Program_Entry
                AND he.Employment_Status_at_Program_Entry = DIM_Intake_Characteristics.Employment_Status_at_Program_Entry
                AND he.Long_Term_Unemployment_at_Program_Entry = DIM_Intake_Characteristics.Long_Term_Unemployment_at_Program_Entry
                AND he.Exhausting_TANF_Within_2_Yrs_at_Program_Entry = DIM_Intake_Characteristics.Exhausting_TANF_Within_2_Yrs_at_Program_Entry
                AND he.Foster_Care_Youth_Status_at_Program_Entry = DIM_Intake_Characteristics.Foster_Care_Youth_Status_at_Program_Entry
                AND he.Homeless_or_Runaway_at_Program_Entry = DIM_Intake_Characteristics.Homeless_or_Runaway_at_Program_Entry
                AND he.Ex_Offender_Status_at_Program_Entry = DIM_Intake_Characteristics.Ex_Offender_Status_at_Program_Entry
                AND he.Low_Income_Status_at_Program_Entry = DIM_Intake_Characteristics.Low_Income_Status_at_Program_Entry
                AND he.English_Language_Learner_at_Program_Entry = DIM_Intake_Characteristics.English_Language_Learner_at_Program_Entry
                AND he.Low_Levels_of_Literacy_at_Program_Entry = DIM_Intake_Characteristics.Low_Levels_of_Literacy_at_Program_Entry
                AND he.Cultural_Barriers_at_Program_Entry = DIM_Intake_Characteristics.Cultural_Barriers_at_Program_Entry
                AND he.Single_Parent_at_Program_Entry = DIM_Intake_Characteristics.Single_Parent_at_Program_Entry
                AND he.Displaced_Homemaker_at_Program_Entry = DIM_Intake_Characteristics.Displaced_Homemaker_at_Program_Entry
            ) AS Intake_Characteristics_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = he.program_name
            ) AS Program_Key,
            --Entry Year Quarter Surrogate Key
            he.Entry_Year_Quarter_Key,
            --Exit Year Quarter Surrogate Key
            he.Exit_Year_Quarter_Key,
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
            CAST('' AS CHAR(1)) AS Incarcerated_at_Program_Entry,
            CAST('9999-01-01' AS DATE) AS Date_Released_from_Incarceration,
            CAST('' AS CHAR(1)) AS Other_Reason_for_Exit,
            CAST('' AS CHAR(1)) AS Migrant_and_Seasonal_Farmworker_Status,
            CAST('' AS CHAR(1)) AS Individual_with_a_Disability,
            CAST('' AS CHAR(1)) AS Zip_Code_of_Residence,
            he.Higher_Education_Student_Level,
            he.Higher_Education_Enrollment_Status,
            he.Higher_Education_Tuition_Status
    FROM cteHigherEducation he
)
SELECT DISTINCT
        COALESCE(Person_Key, 0),
        COALESCE(Intake_Characteristics_Key, 0),
        COALESCE(Program_Key, 0),
        COALESCE(Entry_Year_Quarter_Key, 0),
        COALESCE(Exit_Year_Quarter_Key, 0),
        COALESCE(County_of_Residence_Key, 0),
        COALESCE(State_of_Residence_Key, 0),
        COALESCE(CIP_Classification_Key, 0),
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
        Incarcerated_at_Program_Entry,
        Date_Released_from_Incarceration,
        Other_Reason_for_Exit,
        Migrant_and_Seasonal_Farmworker_Status,
        Individual_with_a_Disability,
        Zip_Code_of_Residence,
        Higher_Education_Student_Level,
        Higher_Education_Enrollment_Status, 
        Higher_Education_Tuition_Status
FROM cteFactData;
