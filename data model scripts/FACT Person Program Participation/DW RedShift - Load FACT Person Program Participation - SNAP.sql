/*
  This script will load the the FACT_Person_Program_Participation table with data for the "Supplemental Nutrition Assistance Program (SNAP)" program.
    Step 1
        Find unique eligible cases and associate each unique case with a entry quarter and an exit quarter.
        The cert_start_date is used to determine the entry quarter and the cert_end_date is used to determine the exit quarter.
        The results are returned in the cteSNAPEligibleCase common table expression (CTE).
    Step 2
        Sum gross_monthly_income and net_monthly_income grouping on case, ssn, start quarter and exit quarter.
        The results are returned in the cteSNAPIncome CTE.
    Step 3
        Collect data for each case found in step 1 and supplement that data with the aggregated income values from step 2.
        The results are returned in the cteSNAP CTE.
    Step 4
        Lookup the dimension keys for eacn cteSNap record.
        The results are returned in the cteFactData CTE.
    Step 5
        The cteFactData is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Participation (SNAP)
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
WITH cteSNAPEligibleCase (case_unit_id, entry_quarter_key, exit_quarter_key, entry_file_date, exit_file_date)
AS
(
    SELECT  snap_case.case_unit_id,
            entry_qtr.Year_Quarter_Key,
            exit_qtr.Year_Quarter_Key,
            MIN(file_month),
            MAX(file_month)
    FROM ds_ar_dhs.snap_case
    INNER JOIN DIM_Year_Quarter entry_qtr
        ON snap_case.cert_start_date BETWEEN entry_qtr.Quarter_Start_Date AND entry_qtr.Quarter_End_Date
    INNER JOIN DIM_Year_Quarter exit_qtr
        ON snap_case.cert_end_date BETWEEN exit_qtr.Quarter_Start_Date AND exit_qtr.Quarter_End_Date
    WHERE DATEPART(YEAR, snap_case.file_month) >= 2010
    AND DATEPART(YEAR, snap_case.cert_end_date) >= 2010
    AND snap_case.snap_eligibility = '1'
    AND snap_case.file_month BETWEEN snap_case.cert_start_date AND snap_case.cert_end_date
    GROUP BY snap_case.case_unit_id, entry_qtr.Year_Quarter_Key, exit_qtr.Year_Quarter_Key
),
--select * from ctesnapeligiblecase;
cteSNAPIncome (case_unit_id, social_security_number, entry_quarter_key, exit_quarter_key, gross_monthly_income, net_monthly_income, file_month)
AS
(
    SELECT  sec.case_unit_id,
            si.SSN,
            sec.entry_quarter_key,
            sec.exit_quarter_key,
            SUM(CASE WHEN si.gross_income_mo_indicator = 1 THEN si.gross_income_mo ELSE 0 END) AS gross_monthly_income,
            SUM(CASE WHEN si.net_income_mo_indicator = 1 THEN si.net_income_mo ELSE 0 END) AS net_monthly_income,
            MIN(si.file_month)
    FROM cteSNAPEligibleCase sec
    INNER JOIN ds_ar_dhs.snap_individual si
        ON sec.case_unit_id = si.case_unit_id
        AND si.file_month BETWEEN sec.entry_file_date AND sec.exit_file_date
    WHERE si.valid_ssn_format = 'Y'
    AND si.ssn NOT IN (SELECT DISTINCT ssn FROM ds_ar_dhs.snap_individual GROUP BY ssn, file_month HAVING COUNT(*) > 10)
    GROUP BY sec.case_unit_id, si.SSN, sec.entry_quarter_key, sec.exit_quarter_key
),
cteSNAP (social_security_number, program_name, entry_quarter_key, exit_quarter_key, state_abbreviation,
         Highest_School_Grade_Completed_at_Program_Entry, Highest_Education_Level_Completed_at_Program_Entry, School_Status_at_Program_Entry,
         Employment_Status_at_Program_Entry, Long_Term_Unemployment_at_Program_Entry, Exhausting_TANF_Within_2_Yrs_at_Program_Entry,
         Foster_Care_Youth_Status_at_Program_Entry, Homeless_or_Runaway_at_Program_Entry, Ex_Offender_Status_at_Program_Entry,
         Low_Income_Status_at_Program_Entry, English_Language_Learner_at_Program_Entry, Low_Levels_of_Literacy_at_Program_Entry,
         Cultural_Barriers_at_Program_Entry, Single_Parent_at_Program_Entry, Displaced_Homemaker_at_Program_Entry,
         Gross_Monthly_Income, Net_Monthly_Income)
AS
(
    SELECT DISTINCT
            --LOOKUP VALUE FOR PERSON KEY
            cteSNAPIncome.social_security_number,
            --LOOKUP VALUE FOR PROGRAM KEY
            CAST('Supplemental Nutrition Assistance Program (SNAP)' AS VARCHAR(75)) AS program_name,
            --ENTRY YEAR QUARTER KEY
            cteSNAPIncome.entry_quarter_key,
            --EXIT YEAR QUARTER KEY
            cteSNAPIncome.exit_quarter_key,
            --LOOKUP VALUE FOR STATE KEY
            snap.state AS state_abbreviation,
            --LOOKUP VALUES FOR INTAKE CHARACTERISTICS KEY
            CASE
                WHEN snap.highest_ed = '1' THEN '0'
                WHEN snap.highest_ed = '1G' THEN '1'
                WHEN snap.highest_ed = '2G' THEN '2'
                WHEN snap.highest_ed = '3G' THEN '3'
                WHEN snap.highest_ed = '4G' THEN '4'
                WHEN snap.highest_ed = '5G' THEN '5'
                WHEN snap.highest_ed = '6G' THEN '6'
                WHEN snap.highest_ed = '7G' THEN '7'
                WHEN snap.highest_ed = '8G' THEN '8'
                WHEN snap.highest_ed = '9G' THEN '9'
                WHEN snap.highest_ed = '10G' THEN '10'
                WHEN snap.highest_ed = '11G' THEN '11'
                WHEN snap.highest_ed IN ('12G', '13', '14', '15', '16', '17', '18', '19', '20', '21') THEN '12'
                ELSE ''
            END AS Highest_School_Grade_Completed_at_Program_Entry,
            CASE snap.highest_ed
                WHEN '13' THEN 'Attained secondary school diploma'
                WHEN '14' THEN 'Attained a secondary school equivalency'
                WHEN '16' THEN 'Completed one of more years of postsecondary education'
                WHEN '17' THEN 'Attained an Associate degree'
                WHEN '18' THEN 'Attained a Bachelor degree'
                WHEN '19' THEN 'Attained a degree beyond a Bachelor degree'
                WHEN '20' THEN 'Attained a degree beyond a Bachelor degree'
                WHEN '21' THEN 'Attained a degree beyond a Bachelor degree'
                WHEN '1' THEN 'No Educational Level Completed'
                ELSE ''
            END AS Highest_Education_Level_Completed_at_Program_Entry,
            CAST('' AS CHAR(1)) AS School_Status_at_Program_Entry,
            CASE snap.employment
                WHEN '1' THEN 'Employed'
                WHEN '2' THEN 'Employed'
                WHEN '3' THEN 'Employed'
                WHEN '6' THEN 'Not in labor force'
                WHEN '4' THEN 'Unemployed'
                ELSE ''
            END AS Employment_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Long_Term_Unemployment_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Exhausting_TANF_Within_2_Yrs_at_Program_Entry,
            CASE
                WHEN snap.relationship = '01' and snap.rel_child = '4' THEN 'Yes'
                WHEN snap.relationship = '01' and snap.rel_child IN ('1', '2', '3') THEN 'No'
                WHEN snap.relationship IN ('00', '02', '03', '04', '05', '06', '07') then 'No'
                ELSE ''
            END AS Foster_Care_Youth_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Homeless_or_Runaway_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Ex_Offender_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Low_Income_Status_at_Program_Entry,
            CAST('' AS CHAR(1)) AS English_Language_Learner_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Low_Levels_of_Literacy_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Cultural_Barriers_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Single_Parent_at_Program_Entry,
            CAST('' AS CHAR(1)) AS Displaced_Homemaker_at_Program_Entry,
            --FACT MEASURES
            CAST(cteSNAPIncome.gross_monthly_income AS DECIMAL(14,2)) AS Gross_Monthly_Income,
            CAST(cteSNAPIncome.net_monthly_income AS DECIMAL(14,2)) AS Net_Monthly_Income
    FROM cteSNAPIncome
    INNER JOIN ds_ar_dhs.snap_individual snap
        ON cteSNAPIncome.case_unit_id = snap.case_unit_id
        AND cteSNAPIncome.social_security_number = snap.ssn
        AND cteSNAPIncome.file_month = snap.file_month
    WHERE DATEPART(YEAR, snap.file_month) >= 2010
),
cteFactData (Person_Key, Intake_Characteristics_Key, Program_Key, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key, County_of_Residence_Key,
             State_of_Residence_Key, CIP_Classification_Key, Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service,
             Received_Training, Eligible_Training_Provider_Name, Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1,
             Type_of_Training_Service_1, Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
             Participated_in_Postsecondary_Education_During_Program_Participation, Received_Training_from_Private_Section_Operated_Program,
             Enrolled_in_Secondary_Education_Program, Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
             Youth_4th_Quarter_Placement, Incarcerated_at_Program_Entry, Date_Released_from_Incarceration, Other_Reason_for_Exit,
             Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability, Zip_Code_of_Residence, Higher_Education_Student_Level,
             Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = snap.social_security_number
            ) AS Person_Key,
            --Lookup Intake Characteristics Surrogate Key
            (
                SELECT DIM_Intake_Characteristics.Intake_Characteristics_Key
                FROM DIM_Intake_Characteristics
                WHERE snap.Highest_School_Grade_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_School_Grade_Completed_at_Program_Entry
                AND snap.Highest_Education_Level_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_Education_Level_Completed_at_Program_Entry
                AND snap.School_Status_at_Program_Entry = DIM_Intake_Characteristics.School_Status_at_Program_Entry
                AND snap.Employment_Status_at_Program_Entry = DIM_Intake_Characteristics.Employment_Status_at_Program_Entry
                AND snap.Long_Term_Unemployment_at_Program_Entry = DIM_Intake_Characteristics.Long_Term_Unemployment_at_Program_Entry
                AND snap.Exhausting_TANF_Within_2_Yrs_at_Program_Entry = DIM_Intake_Characteristics.Exhausting_TANF_Within_2_Yrs_at_Program_Entry
                AND snap.Foster_Care_Youth_Status_at_Program_Entry = DIM_Intake_Characteristics.Foster_Care_Youth_Status_at_Program_Entry
                AND snap.Homeless_or_Runaway_at_Program_Entry = DIM_Intake_Characteristics.Homeless_or_Runaway_at_Program_Entry
                AND snap.Ex_Offender_Status_at_Program_Entry = DIM_Intake_Characteristics.Ex_Offender_Status_at_Program_Entry
                AND snap.Low_Income_Status_at_Program_Entry = DIM_Intake_Characteristics.Low_Income_Status_at_Program_Entry
                AND snap.English_Language_Learner_at_Program_Entry = DIM_Intake_Characteristics.English_Language_Learner_at_Program_Entry
                AND snap.Low_Levels_of_Literacy_at_Program_Entry = DIM_Intake_Characteristics.Low_Levels_of_Literacy_at_Program_Entry
                AND snap.Cultural_Barriers_at_Program_Entry = DIM_Intake_Characteristics.Cultural_Barriers_at_Program_Entry
                AND snap.Single_Parent_at_Program_Entry = DIM_Intake_Characteristics.Single_Parent_at_Program_Entry
                AND snap.Displaced_Homemaker_at_Program_Entry = DIM_Intake_Characteristics.Displaced_Homemaker_at_Program_Entry
            ) AS Intake_Characteristics_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = snap.program_name
            ) AS Program_Key,
            --Entry Year Quarter Surrogate Key
            snap.entry_quarter_key AS Entry_Year_Quarter_Key,
            --Exit Year Quarter Surrogate Key
            snap.exit_quarter_key AS Exit_Year_Quarter_Key,
            --County Surrogate Key
            0 AS County_of_Residence_Key,   -- source data does not contain county of residence
            --Lookup State Surrogate Key
            (
                SELECT DIM_State.State_Key
                FROM DIM_State
                WHERE DIM_State.State_Abbreviation = snap.state_abbreviation
            ) AS State_of_Residence_Key,
            --CIP Surrogate Key
            0 AS CIP_Classification_Key,    -- source data does not contain CIP Classification
            --Measures
            snap.Gross_Monthly_Income AS Gross_Monthly_Income,
            snap.Net_Monthly_Income AS Net_Monthly_Income,
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
            CAST('' AS CHAR(1)) AS Participated_in_Postsecondary_Education_During_Program_Participation,
            CAST('' AS CHAR(1)) AS Received_Training_from_Private_Section_Operated_Program,
            CAST('' AS CHAR(1)) AS Enrolled_in_Secondary_Education_Program,
            CAST('9999-01-01' AS DATE) AS Date_Enrolled_in_Post_Exit_Education_or_Training_Program,
            CAST('' AS CHAR(1)) AS Youth_2nd_Quarter_Placement,
            CAST('' AS CHAR(1)) AS Youth_4th_Quarter_Placement,
            CAST('' AS CHAR(1)) AS Incarcerated_at_Program_Entry,
            CAST('9999-01-01' AS DATE) AS Date_Released_from_Incarceration,
            CAST('' AS CHAR(1)) AS Other_Reason_for_Exit,
            CAST('' AS CHAR(1)) AS Migrant_and_Seasonal_Farmworker_Status,
            CAST('' AS CHAR(1)) AS Individual_with_a_Disability,
            CAST('' AS CHAR(1)) AS Zip_Code_of_Residence,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Student_Level,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Enrollment_Status,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Tuition_Status
    FROM cteSNAP snap
)
SELECT  COALESCE(Person_Key, 0),
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
