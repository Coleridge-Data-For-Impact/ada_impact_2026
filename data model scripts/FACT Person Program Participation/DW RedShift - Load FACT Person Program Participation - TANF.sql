/*
  This script will load the the FACT_Person_Program_Participation table with data for the "Temporary Assistance for Needy Families (TANF)" program.
    Step 1
        Get a list of exit records for each ssn and reporting_month.
        Exit record will have tanf_end_of_spell = 'TRUE'.
        We only want the records that have tanf_start_of_spell = 'FALSE' in this step.
        The results are returned in the cteSpellEnd common table expression (CTE).
    Step 2
        Calculate TANF spells for each person by looking for record that have tanf_start_of_spell = 'TRUE'.
        Records that have tanf_end_of_spell = 'FALSE' will be matched to the nearest exit data from Step 1.
        Records that have tanf_end_of_spell = 'TRUE' will use the tanf_end_of_spell as the exit date.
        The results are returned in the cteTANFSpell CTE.
    Step 3
        Collect data for each case found in step 2.
        The results are returned in the cteTANF CTE.
    Step 4
        Lookup the dimension keys for each cteTANF record.
        The results are returned in the cteFactData CTE.
    Step 5
        The cteFactData is inserted into the fact table.  Any keys that could not be found via the lookup are set to 0.
*/

-- FACT Person Program Participation (TANF)
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
WITH cteSpellEnd (social_security_number, reporting_month)
AS
(
    SELECT DISTINCT social_security_number, reporting_month
    FROM ds_ar_dhs.tanf_member
    WHERE tanf_start_of_spell = 'FALSE'
    AND tanf_end_of_spell = 'TRUE'
    AND LEFT(reporting_month, 4) >= '2010'
    AND LEN(tanf_member.reporting_month) = 6
    AND valid_ssn_format = 'Y'
),
cteTANFSpell (social_security_number, entry_date, exit_date)
AS
(
    SELECT  ts.social_security_number,
            TO_DATE(CONCAT(ts.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD'),
            CASE
                WHEN MIN(cteSpellEnd.reporting_month) IS NULL THEN TO_DATE('9999-01-01', 'YYYYMMDD')
                ELSE TO_DATE(CONCAT(MIN(cteSpellEnd.reporting_month), CAST('01' AS CHAR(2))), 'YYYYMMDD')
            END
    FROM ds_ar_dhs.tanf_member ts
    LEFT JOIN cteSpellEnd
        ON ts.social_security_number = cteSpellEnd.social_security_number
        AND ts.reporting_month < cteSpellEnd.reporting_month
    WHERE ts.tanf_start_of_spell = 'TRUE'
    AND ts.tanf_end_of_spell = 'FALSE'
    AND LEFT(ts.reporting_month, 4) >= '2010'
    AND LEN(ts.reporting_month) = 6
    AND ts.valid_ssn_format = 'Y'
    GROUP BY ts.social_security_number, ts.reporting_month
    UNION 
    SELECT  tm.social_security_number,
            TO_DATE(CONCAT(tm.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD'),
            TO_DATE(CONCAT(tm.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD')
    FROM ds_ar_dhs.tanf_member tm
    WHERE tm.tanf_start_of_spell = 'TRUE'
    AND tm.tanf_end_of_spell = 'TRUE'
    AND LEFT(tm.reporting_month, 4) >= '2010'
    AND LEN(tm.reporting_month) = 6
    AND tm.valid_ssn_format = 'Y'
),
cteTANF (social_security_number, program_name, entry_date, exit_date, state_fips_code, Highest_School_Grade_Completed_at_Program_Entry,
         Highest_Education_Level_Completed_at_Program_Entry, School_Status_at_Program_Entry, Employment_Status_at_Program_Entry,
         Long_Term_Unemployment_at_Program_Entry, Exhausting_TANF_Within_2_Yrs_at_Program_Entry, Foster_Care_Youth_Status_at_Program_Entry,
         Homeless_or_Runaway_at_Program_Entry, Ex_Offender_Status_at_Program_Entry, Low_Income_Status_at_Program_Entry,
         English_Language_Learner_at_Program_Entry, Low_Levels_of_Literacy_at_Program_Entry, Cultural_Barriers_at_Program_Entry,
         Single_Parent_at_Program_Entry, Displaced_Homemaker_at_Program_Entry)
AS
(
    SELECT DISTINCT
            --LOOKUP VALUE FOR PERSON KEY
            cteTANFSpell.social_security_number,
            --LOOKUP VALUE FOR PROGRAM KEY
            CAST('Temporary Assistance for Needy Families (TANF)' AS VARCHAR(75)),
            --LOOKUP VALUE FOR ENTRY YEAR QUARTER KEY
            cteTANFSpell.entry_date,
            --LOOKUP VALUE FOR EXIT YEAR QUARTER KEY
            cteTANFSpell.exit_date,
            --LOOKUP VALUE FOR STATE KEY
            tanf_member.state_fips_code,
            --LOOKUP VALUES FOR INTAKE CHARACTERISTICS KEY
            CASE
                WHEN education_level IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12') THEN education_level
                WHEN education_level IN ('13', '14', '15', '16') THEN '12'
                WHEN education_level = '98' THEN '0'
                ELSE ''
            END AS Highest_School_Grade_Completed_at_Program_Entry,
            CASE education_level
                WHEN '12' THEN 'Attained secondary school diploma'
                WHEN '16' THEN 'Attained a postsecondary technical or vocational certificate (non-degree)'
                WHEN '13' THEN 'Attained an Associate degree'
                WHEN '14' THEN 'Attained a Bachelor degree'
                WHEN '15' THEN 'Attained a degree beyond a Bachelor degree'
                WHEN '98' THEN 'No Educational Level Completed'
                ELSE ''
            END AS Highest_Education_Level_Completed_at_Program_Entry,
            CAST('' AS CHAR(1)) AS School_Status_at_Program_Entry,
            CASE employment_status
                WHEN '1' THEN 'Employed'
                WHEN '3' THEN 'Not in labor force'
                WHEN '2' THEN 'Unemployed'
                ELSE ''
            END AS Employment_Status_at_Program_Entry,
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
            CAST('' AS CHAR(1)) AS Displaced_Homemaker_at_Program_Entry
    FROM cteTANFSpell
    INNER JOIN ds_ar_dhs.tanf_member
        ON cteTANFSpell.social_security_number = tanf_member.social_security_number
        AND cteTANFSpell.entry_date = TO_DATE(CONCAT(tanf_member.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD')
    WHERE tanf_member.tanf_start_of_spell = 'TRUE'
    AND LEFT(tanf_member.reporting_month, 4) >= '2010'
    AND LENGTH (tanf_member.reporting_month) = 6
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
                WHERE DIM_Person.Person_UID = tanf.social_security_number
            ) AS Person_Key,
            --Lookup Intake Characteristics Surrogate Key
            (
                SELECT DIM_Intake_Characteristics.Intake_Characteristics_Key
                FROM DIM_Intake_Characteristics
                WHERE tanf.Highest_School_Grade_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_School_Grade_Completed_at_Program_Entry
                AND tanf.Highest_Education_Level_Completed_at_Program_Entry = DIM_Intake_Characteristics.Highest_Education_Level_Completed_at_Program_Entry
                AND tanf.School_Status_at_Program_Entry = DIM_Intake_Characteristics.School_Status_at_Program_Entry
                AND tanf.Employment_Status_at_Program_Entry = DIM_Intake_Characteristics.Employment_Status_at_Program_Entry
                AND tanf.Long_Term_Unemployment_at_Program_Entry = DIM_Intake_Characteristics.Long_Term_Unemployment_at_Program_Entry
                AND tanf.Exhausting_TANF_Within_2_Yrs_at_Program_Entry = DIM_Intake_Characteristics.Exhausting_TANF_Within_2_Yrs_at_Program_Entry
                AND tanf.Foster_Care_Youth_Status_at_Program_Entry = DIM_Intake_Characteristics.Foster_Care_Youth_Status_at_Program_Entry
                AND tanf.Homeless_or_Runaway_at_Program_Entry = DIM_Intake_Characteristics.Homeless_or_Runaway_at_Program_Entry
                AND tanf.Ex_Offender_Status_at_Program_Entry = DIM_Intake_Characteristics.Ex_Offender_Status_at_Program_Entry
                AND tanf.Low_Income_Status_at_Program_Entry = DIM_Intake_Characteristics.Low_Income_Status_at_Program_Entry
                AND tanf.English_Language_Learner_at_Program_Entry = DIM_Intake_Characteristics.English_Language_Learner_at_Program_Entry
                AND tanf.Low_Levels_of_Literacy_at_Program_Entry = DIM_Intake_Characteristics.Low_Levels_of_Literacy_at_Program_Entry
                AND tanf.Cultural_Barriers_at_Program_Entry = DIM_Intake_Characteristics.Cultural_Barriers_at_Program_Entry
                AND tanf.Single_Parent_at_Program_Entry = DIM_Intake_Characteristics.Single_Parent_at_Program_Entry
                AND tanf.Displaced_Homemaker_at_Program_Entry = DIM_Intake_Characteristics.Displaced_Homemaker_at_Program_Entry
            ) AS Intake_Characteristics_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = tanf.program_name
            ) AS Program_Key,
            --Lookup Entry Year Quarter Surrogate Key
            (
                SELECT entry_qtr.Year_Quarter_Key
                FROM DIM_Year_Quarter entry_qtr
                WHERE tanf.entry_date between entry_qtr.quarter_start_date AND entry_qtr.quarter_end_date      
            ) AS Entry_Year_Quarter_Key,
            --Lookup Exit Year Quarter Surrogate Key
            (
                SELECT exit_qtr.Year_Quarter_Key
                FROM DIM_Year_Quarter exit_qtr
                WHERE tanf.exit_date between exit_qtr.quarter_start_date and exit_qtr.quarter_end_date
            ) AS Exit_Year_Quarter_Key,
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
            CAST('' AS CHAR(1)) AS Incarcerated_at_Program_Entry,
            CAST('9999-01-01' AS DATE) AS Date_Released_from_Incarceration,
            CAST('' AS CHAR(1)) AS Other_Reason_for_Exit,
            CAST('' AS CHAR(1)) AS Migrant_and_Seasonal_Farmworker_Status,
            CAST('' AS CHAR(1)) AS Individual_with_a_Disability,
            CAST('' AS CHAR(1)) AS Zip_Code_of_Residence,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Student_Level,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Enrollment_Status,
            CAST('' AS VARCHAR(100)) AS Higher_Education_Tuition_Status
    FROM cteTANF tanf
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
