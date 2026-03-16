/*
  This script will load the the FACT_Person_Program_Observation_Quarter table with data for the "Temporary Assistance for Needy Families (TANF)" program.
    Step 1
        Get a list of exit records for each ssn and observation quarter.
        The observation quarter is calculated from the reporting_month.
        The results are returned in the cteTANFQuarter common table expression (CTE).
    Step 2
        Collect data for each record in cteTANFQuarter.
        The results are returned in the cteTANF CTE.
    Step 3
        Lookup the dimension keys for each cteTANF record.
        The results are returned in the cteFactData CTE.
    Step 4
        The cteFactData is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Observation Quarter (TANF)
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
WITH cteTANFQuarter (social_security_number, year_qtr_key, qtr_first_month, qtr_second_month, qtr_third_month, reporting_month)
AS
(
    SELECT  tanf_member.social_security_number,
            qtr.Year_Quarter_Key,
            MAX(CASE WHEN RIGHT(tanf_member.reporting_month, 2) IN ('01', '04', '07', '10') THEN 'Yes' ELSE 'No' END) AS qtr_first_month,
            MAX(CASE WHEN RIGHT(tanf_member.reporting_month, 2) IN ('02', '05', '08', '11') THEN 'Yes' ELSE 'No' END) AS qtr_second_month,
            MAX(CASE WHEN RIGHT(tanf_member.reporting_month, 2) IN ('03', '06', '09', '12') THEN 'Yes' ELSE 'No' END) AS qtr_third_month,
            MIN(tanf_member.reporting_month)
    FROM ds_ar_dhs.tanf_member
    INNER JOIN DIM_Year_Quarter qtr
        ON TO_DATE(CONCAT(tanf_member.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD') BETWEEN qtr.Quarter_Start_Date AND qtr.Quarter_End_Date
    WHERE LEFT(tanf_member.reporting_month, 4) >= '2010'
    AND LEN(tanf_member.reporting_month) = 6
    AND tanf_member.valid_ssn_format = 'Y'
    GROUP BY tanf_member.social_security_number, qtr.Year_Quarter_Key
),
cteTANF (social_security_number, program_name, year_qtr_key, state_fips_code, Enrolled_Entire_Quarter,
         Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
AS
(
    SELECT DISTINCT
            --LOOKUP VALUE FOR PERSON KEY
            tanf_member.social_security_number,
            --LOOKUP VALUE FOR PROGRAM KEY
            CAST('Temporary Assistance for Needy Families (TANF)' AS VARCHAR(75)) AS program_name,
            --OBSERVATION YEAR QUARTER KEY
            cteTANFQuarter.year_qtr_key,
            --LOOKUP VALUE FOR STATE KEY
            tanf_member.state_fips_code,
            --Measures
            CASE
                WHEN cteTANFQuarter.qtr_first_month = 'Yes' AND cteTANFQuarter.qtr_second_month = 'Yes' AND cteTANFQuarter.qtr_third_month = 'Yes' THEN 'Yes'
                ELSE 'No'
            END AS Enrolled_Entire_Quarter,
            cteTANFQuarter.qtr_first_month AS Enrolled_First_Month_of_Quarter,
            cteTANFQuarter.qtr_second_month AS Enrolled_Second_Month_of_Quarter,
            cteTANFQuarter.qtr_third_month AS Enrolled_Third_Month_of_Quarter
    FROM cteTANFQuarter
    INNER JOIN ds_ar_dhs.tanf_member
        ON cteTANFQuarter.social_security_number = tanf_member.social_security_number
        AND cteTANFQuarter.reporting_month = tanf_member.reporting_month
    WHERE LEFT(tanf_member.reporting_month, 4) >= '2010'
    AND LEN(tanf_member.reporting_month) = 6
    AND tanf_member.valid_ssn_format = 'Y'
),
cteFactData (Person_Key, Program_Key, Observation_Year_Quarter_Key, County_of_Residence_Key, State_of_Residence_Key, CIP_Classification_Key,
             Enrolled_Entire_Quarter, Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter,
             Gross_Monthly_Income, Net_Monthly_Income, Date_of_Most_Recent_Career_Service, Received_Training, Eligible_Training_Provider_Name,
             Eligible_Training_Provider_Program_of_Study, Date_Entered_Training_1, Type_of_Training_Service_1,
             Date_Entered_Training_2, Type_of_Training_Service_2, Date_Entered_Training_3, Type_of_Training_Service_3, 
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
                WHERE DIM_Person.Person_UID = tanf.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = tanf.program_name
            ) AS Program_Key,
            --Observation Year Quarter Surrogate Key
            tanf.year_qtr_key AS Observation_Year_Quarter_Key,
            --County Surrogate Key
            0 AS County_of_Residence_Key,   -- source data does not contain county of residence
            --Lookup State Surrogate Key
            (
                SELECT DIM_State.State_Key
                FROM DIM_State
                WHERE DIM_State.State_FIPS_Code = tanf.state_fips_code
            ) AS State_of_Residence_Key,    -- source data does not contain state of residence
            --CIP Surrogate Key
            0 AS CIP_Classification_Key,    -- source data does not contain CIP Classification
            --Measures
            tanf.Enrolled_Entire_Quarter,
            tanf.Enrolled_First_Month_of_Quarter,
            tanf.Enrolled_Second_Month_of_Quarter,
            tanf.Enrolled_Third_Month_of_Quarter,
            0 AS Gross_Monthly_Income,      -- source data does not contain gross monthly income
            0 AS Net_Monthly_Income,        -- source data does not contain net monthly income
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
            CAST('' AS CHAR(1)) AS Higher_Education_Student_Level,
            CAST('' AS CHAR(1)) AS Higher_Education_Enrollment_Status,
            CAST('' AS CHAR(1)) AS Higher_Education_Tuition_Status
    FROM cteTANF tanf
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
