/*
  This script will load the the FACT_Person_Program_Observation_Quarter table with data for the "Supplemental Nutrition Assistance Program (SNAP)" program.
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

-- FACT Person Program Observation Quarter (SNAP)
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
WITH cteSNAPEligibleCase (case_unit_id, year_qtr_key, start_file_date, end_file_date)
AS
(
    SELECT  snap_case.case_unit_id,
            obs_qtr.Year_Quarter_Key AS year_qtr_key,
            MIN(file_month) AS start_file_date,
            MAX(file_month) AS end_file_date
    FROM ds_ar_dhs.snap_case
    INNER JOIN DIM_Year_Quarter obs_qtr
        ON snap_case.file_month BETWEEN obs_qtr.Quarter_Start_Date AND obs_qtr.Quarter_End_Date
    WHERE DATEPART(YEAR, snap_case.file_month) >= 2010
    AND snap_case.snap_eligibility = 1
    AND snap_case.file_month BETWEEN snap_case.cert_start_date AND snap_case.cert_end_date
    GROUP BY snap_case.case_unit_id, obs_qtr.Year_Quarter_Key
),
cteSNAPIncome (case_unit_id, social_security_number, year_qtr_key, qtr_first_month, qtr_second_month,
               qtr_third_month, gross_monthly_income, net_monthly_income, file_month)
AS
(
    SELECT  sec.case_unit_id,
            si.SSN AS social_security_number,
            sec.year_qtr_key,
            MAX(CASE WHEN DATEPART(MONTH, si.file_month) IN (1, 4, 7, 10) THEN 'Yes' ELSE 'No' END) AS qtr_first_month,
            MAX(CASE WHEN DATEPART(MONTH, si.file_month) IN (2, 5, 8, 11) THEN 'Yes' ELSE 'No' END) AS qtr_second_month,
            MAX(CASE WHEN DATEPART(MONTH, si.file_month) IN (3, 6, 9, 12) THEN 'Yes' ELSE 'No' END) AS qtr_third_month,
            SUM(CASE WHEN si.gross_income_mo_indicator = 1 THEN si.gross_income_mo ELSE 0 END) AS gross_monthly_income,
            SUM(CASE WHEN si.net_income_mo_indicator = 1 THEN si.net_income_mo ELSE 0 END) AS net_monthly_income,
            MIN(si.file_month)
    FROM cteSNAPEligibleCase sec
    INNER JOIN ds_ar_dhs.snap_individual si
        ON sec.case_unit_id = si.case_unit_id
        AND si.file_month BETWEEN sec.start_file_date AND sec.end_file_date
    WHERE si.valid_ssn_format = 1
    AND si.ssn NOT IN (SELECT DISTINCT ssn FROM ds_ar_dhs.snap_individual GROUP BY ssn, file_month HAVING COUNT(*) > 10)
    GROUP BY sec.case_unit_id, si.SSN, sec.year_qtr_key
),
cteSNAP (social_security_number, program_name, year_qtr_key, state_abbreviation, Enrolled_Entire_Quarter,
         Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter,
         Gross_Monthly_Income, Net_Monthly_Income)
AS
(
    SELECT DISTINCT
            --LOOKUP VALUE FOR PERSON KEY
            cteSNAPIncome.social_security_number,
            --LOOKUP VALUE FOR PROGRAM KEY
            CAST('Supplemental Nutrition Assistance Program (SNAP)' AS VARCHAR(75)) AS program_name,
            --OBSERVATION YEAR QUARTER KEY
            cteSNAPIncome.year_qtr_key,
            --LOOKUP VALUE FOR STATE KEY
            snap.state AS state_abbreviation,
            --Measures
            CASE
                WHEN cteSNAPIncome.qtr_first_month = 'Yes' AND cteSNAPIncome.qtr_second_month = 'Yes' AND cteSNAPIncome.qtr_third_month = 'Yes' THEN 'Yes'
                ELSE 'No'
            END AS Enrolled_Entire_Quarter,
            cteSNAPIncome.qtr_first_month AS Enrolled_First_Month_of_Quarter,
            cteSNAPIncome.qtr_second_month AS Enrolled_Second_Month_of_Quarter,
            cteSNAPIncome.qtr_third_month AS Enrolled_Third_Month_of_Quarter,
            CAST(cteSNAPIncome.gross_monthly_income AS DECIMAL(14,2)) AS Gross_Monthly_Income,
            CAST(cteSNAPIncome.net_monthly_income AS DECIMAL(14,2)) AS Net_Monthly_Income
    FROM cteSNAPIncome
    INNER JOIN ds_ar_dhs.snap_individual snap
        ON cteSNAPIncome.case_unit_id = snap.case_unit_id
        AND cteSNAPIncome.social_security_number = snap.ssn
        AND cteSNAPIncome.file_month = snap.file_month
    WHERE DATEPART(YEAR, snap.file_month) >= 2010
),
cteFactData (Person_Key, Program_Key, Observation_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key,
             Enrolled_Entire_Quarter, Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter,
             Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name,
             Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1, Date_Entered_Training_2,
             Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
             Participated_in_Postsecondary_Education_During_Program_Participation, Received_Training_from_Private_Section_Operated_Program,
             Enrolled_in_Secondary_Education_Program, Date_Enrolled_in_Post_Exit_Education_or_Training_Program, Youth_2nd_Quarter_Placement, 
             Youth_4th_Quarter_Placement, Other_Reason_for_Exit, Migrant_and_Seasonal_Farmworker_Status, Individual_with_a_Disability,
             Zip_Code_of_Residence, Higher_Education_Student_Level, Higher_Education_Enrollment_Status, Higher_Education_Tuition_Status)
AS
(
    SELECT  --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = snap.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = snap.program_name
            ) AS Program_Key,
            --Observation Year Quarter Surrogate Key
            snap.year_qtr_key AS Observation_Year_Quarter_Key,
            --County Surrogate Key
            0 AS County_of_Residence_Key,   -- source data does not contain county of residence
            --Lookup State Surrogate Key
            (
                SELECT DIM_State.State_Key
                FROM DIM_State
                WHERE DIM_State.State_Abbreviation = snap.state_abbreviation
            ) AS State_of_Residence_Key,    -- source data does not contain state of residence
            --CIP Surrogate Key
            0 AS CIP_Classification_Key,    -- source data does not contain CIP Classification
            --Measures
            snap.Enrolled_Entire_Quarter,
            snap.Enrolled_First_Month_of_Quarter,
            snap.Enrolled_Second_Month_of_Quarter,
            snap.Enrolled_Third_Month_of_Quarter,
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