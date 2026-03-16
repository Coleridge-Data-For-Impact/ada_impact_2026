/*
This script will load the FACT Person Quarterly Program Enrollment table with data for the "Adult Education (JOINT)" program.
    Step 1
        People with program enrollments in the source table (ds_ar_dws.jointpirl_raw_data) are returned in the ctePIRL comment table expression (CTE).
        Redundancy in the source data requires grouping  the enrollments for an individual and program entry date in order to determine
        the correct program exit date.  The program exit date can be null is some situation and any null dates are converted to the 
        current date in step 2.
        The results of this step are returned in the ctePIRL common table expression (CTE).
    Step 2
        The entry and exit dates in the ctePIRL CTE are converted to an entry quarter and an exit quarter.  If the exit date is null then
        the current date is used as the exit date.
        The results of this step are returned in the cteQuarterRange CTE.
    Step 3
        This step looks up the dimension keys for the person and program and expands the results to include every quarter between the entry
        quarter and exit quarter (inclusive).  The minimm entry date or maximum exit date are used to calculate the
        Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, and Enrolled_Third_Month_of_Quarter indicators for the first
        and last quarters in the enrollment period.  All quarters between the entry and exit are assumed to include all months in the quarter.
        The results will include all quarters for each enrollment period a person might have.
        The results of this step are returned in the cteFactData CTE.
    Step 4
        The value of the Enrolled_Entire_Quarter indicator is calculated and the results inserted into the fact table.
*/

-- FACT Person Quarterly Program Enrollment (Joint PIRL)
INSERT INTO FACT_Person_Quarterly_Program_Enrollment (Person_Key, Program_Key, enrollment_year_quarter_key, Enrolled_Entire_Quarter,
                                                      Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
WITH ctePirl (social_security_number, entry_date, exit_date)
AS
(
    SELECT social_security_number, date_of_program_entry_wioa, MAX(date_of_program_exit_wioa)
    FROM ds_ar_dws.jointpirl_raw_data
    WHERE DATEPART(year, date_of_program_entry_wioa) >= 2010
    AND ssn_valid_format = 1
    AND adult_education_wioa = 1
    GROUP BY social_security_number, date_of_program_entry_wioa
),
cteQuarterRange (social_security_number, entry_quarter_key, exit_quarter_key, min_entry_date, max_exit_date)
AS
(
    SELECT  ctePirl.social_security_number,
            entry_qtr.Year_Quarter_Key AS entry_quarter_key,
            exit_qtr.Year_Quarter_Key AS exit_quarter_key,
            MIN(ctePirl.entry_date) AS min_entry_date,
            MAX(COALESCE(ctePirl.exit_date, GETDATE())) AS max_exit_date
    FROM ctePirl
    INNER JOIN DIM_Year_Quarter entry_qtr
        ON ctePirl.entry_date BETWEEN entry_qtr.quarter_start_date AND entry_qtr.quarter_end_date     
    INNER JOIN DIM_Year_Quarter exit_qtr
        ON COALESCE(ctePirl.exit_date, GETDATE()) BETWEEN exit_qtr.quarter_start_date and exit_qtr.quarter_end_date
    GROUP BY ctePirl.social_security_number, entry_qtr.Year_Quarter_Key, exit_qtr.Year_Quarter_Key
),
cteFactData (Person_Key, Program_Key, Enrollment_Year_Quarter_Key, Enrolled_First_Month_of_Quarter,
             Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
AS
(
    SELECT DISTINCT
            --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM DIM_Person
                WHERE DIM_Person.Person_UID = cteQuarterRange.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM DIM_Program
                WHERE DIM_Program.Program_Name = 'Adult Education (JOINT)'
            ) AS Program_Key,
            qtr.Year_Quarter_Key,
            CASE
                WHEN qtr.Year_Quarter_Key = cteQuarterRange.entry_quarter_key AND DATEPART(MONTH, cteQuarterRange.min_entry_date) NOT IN (1, 4, 7, 10) THEN CAST('No' AS VARCHAR(3))
                ELSE CAST('Yes' AS VARCHAR(3))
            END AS Enrolled_Enrolled_First_Month_of_QuarterEntire_Quarter,
            CASE
                WHEN qtr.Year_Quarter_Key = cteQuarterRange.entry_quarter_key AND DATEPART(MONTH, cteQuarterRange.min_entry_date) IN (3, 6, 9, 12) THEN CAST('No' AS VARCHAR(3))
                WHEN qtr.Year_Quarter_Key = cteQuarterRange.exit_quarter_key AND DATEPART(MONTH, cteQuarterRange.max_exit_date) IN (1, 4, 7, 10) THEN CAST('No' AS VARCHAR(3))
                ELSE CAST('Yes' AS VARCHAR(3))
            END AS Enrolled_Second_Month_of_Quarter,
            CASE
                WHEN qtr.Year_Quarter_Key = cteQuarterRange.exit_quarter_key AND DATEPART(MONTH, cteQuarterRange.max_exit_date) NOT IN (3, 6, 9, 12) THEN CAST('No' AS VARCHAR(3))
                ELSE CAST('Yes' AS VARCHAR(3))
            END AS Enrolled_Third_Month_of_Quarter
    FROM cteQuarterRange
    INNER JOIN DIM_Year_Quarter qtr
        ON qtr.Year_Quarter_Key BETWEEN cteQuarterRange.entry_quarter_key AND cteQuarterRange.exit_quarter_key
)
SELECT  Person_Key,
        Program_Key,
        Enrollment_Year_Quarter_Key,
        CASE
            WHEN MAX(Enrolled_First_Month_of_Quarter) = 'Yes' AND MAX(Enrolled_Second_Month_of_Quarter) = 'Yes' AND MAX(Enrolled_Third_Month_of_Quarter) = 'Yes' THEN 'Yes'
            ELSE 'No'
        END AS Enrolled_Entire_Quarter,
        MAX(Enrolled_First_Month_of_Quarter),
        MAX(Enrolled_Second_Month_of_Quarter),
        MAX(Enrolled_Third_Month_of_Quarter)
FROM cteFactData
GROUP BY Person_Key, Program_Key, Enrollment_Year_Quarter_Key;
