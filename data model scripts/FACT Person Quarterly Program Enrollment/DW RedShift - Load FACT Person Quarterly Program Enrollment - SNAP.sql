/*
This script will load the FACT Person Quarterly Program Enrollment table with data for the "Supplemental Nutrition Assistance Program (SNAP)" program.
    Step 1
        Find file months were people had enrollments in the source tables (ds_ar_dhs.snap_case, ds_ar_dhs.snap_individual).
        The file month's must be within the cert range of an eligible case to be included.
        The results of this step are returned in the cteFileMonths common table expression (CTE).
    Step 2
        File months are mapped to their corresponding quarter and a qtr_month_flag is created to identify which months in the quarter were enrolled.
        The qtr_month_flag is the decimal representation of a binary number where each bit in the binary represents a month.  The first (left most) bit is
        used to represent the first month of the quarter and the third (right most) bit is used for the third month.  The results are grouped on person
        and quarter and the binary month flags are summed together to create the qtr_month_flag which will have a decimal value between
        1 (binary 001) and 7 (binary 111).
        The results are returned in the cteSNAP CTE which should contain one record for each person and quarter that had an enrollment.
    Step 3
        This step looks up the dimension keys for the person and program.  The qtr_month_flag is used to calculate the Enrolled_Entire_Quarter, 
        Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, and Enrolled_Third_Month_of_Quarter indicators.  The results will include
        all quarters for each enrollment period a person might have.
        The results of this step are inserted into the fact table..
*/

-- FACT Person Quarterly Program Enrollment (SNAP)
INSERT INTO tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment (Person_Key, Program_Key, enrollment_year_quarter_key, Enrolled_Entire_Quarter,
                                                      Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
WITH cteFileMonths (social_security_number, file_month)
AS
(
    SELECT DISTINCT snap_individual.SSN, snap_case.file_month
    FROM ds_ar_dhs.snap_case
    INNER JOIN ds_ar_dhs.snap_individual
        ON snap_case.case_unit_id = snap_individual.case_unit_id
        AND snap_case.file_month = snap_individual.file_month
    WHERE snap_case.snap_eligibility = 1
    AND DATEPART(YEAR, snap_case.file_month) >= 2010
    AND snap_case.file_month BETWEEN snap_case.cert_start_date AND snap_case.cert_end_date
    AND snap_individual.valid_ssn_format = 'Y'
),
cteSNAP (social_security_number, enrollment_year_quarter_key, qtr_month_flag)
AS
(
    SELECT  cteFileMonths.social_security_number,
            qtr.Year_Quarter_Key,
            --Decimal representation of a binary flag where the 1st, 2nd, and 3rd month of the quarter are identified as separate bits and added together to create a bitmask.
            --Example 1: If only enrolled in the 2nd month of the quarter, then the 2nd bit will be turned on. [010 (binary) equals 2 (decimal)]
            --Example 2: If enrolled in the 2nd and 3rd months of the quarter, then the 2nd and 3rd bits will be turned on.  [010 + 100 = 110 (binary) equals 6 (decimal)]
            SUM(CASE
                    WHEN DATEPART(MONTH, cteFileMonths.file_month) IN (1, 4, 7, 10) THEN 1  --equals 001 binary
                    WHEN DATEPART(MONTH, cteFileMonths.file_month) IN (2, 5, 8, 11) THEN 2  --equals 010 binary
                    WHEN DATEPART(MONTH, cteFileMonths.file_month) IN (3, 6, 9, 12) THEN 4  --equals 100 binary
                END) AS qtr_month_flag
    FROM cteFileMonths
    INNER JOIN DIM_Year_Quarter qtr
        ON cteFileMonths.file_month BETWEEN qtr.Quarter_Start_Date and qtr.Quarter_End_Date
    GROUP BY cteFileMonths.social_security_number, qtr.Year_Quarter_Key
)
SELECT DISTINCT
        --Lookup Person Surrogate Key
        (
            SELECT DIM_Person.Person_Key
            FROM DIM_Person
            WHERE DIM_Person.Person_UID = cteSNAP.social_security_number
        ) AS Person_Key,
        --Lookup Program Surrogate Key
        (
            SELECT DIM_Program.Program_Key
            FROM DIM_Program
            WHERE DIM_Program.Program_Name = 'Supplemental Nutrition Assistance Program (SNAP)'
        ) AS Program_Key,
        cteSNAP.enrollment_year_quarter_key,
        CASE
            WHEN qtr_month_flag = 7 THEN 'Yes'  --[001 + 010 + 100 = 111 (binary) equals 7 (decimal)]
            ELSE 'No'
        END AS Enrolled_Entire_Quarter,
        CASE
            WHEN qtr_month_flag IN (1, 3, 5, 7) THEN 'Yes'  --If the first bit is on, then the 1st month had an enrollment. (001, 011, 101, 111)
            ELSE 'No'
        END AS Enrolled_First_Month_of_Quarter,
        CASE
            WHEN qtr_month_flag IN (2, 3, 6, 7) THEN 'Yes'  --If the second bit is on, then the 2nd month had an enrollment. (010, 011, 110, 111)
            ELSE 'No'
        END AS Enrolled_Second_Month_of_Quarter,
        CASE
            WHEN qtr_month_flag IN (4, 5, 6, 7) THEN 'Yes'  --If the third bit is on, then the 3rd month had an enrollment. (100, 101, 110, 111)
            ELSE 'No'
        END AS Enrolled_Third_Month_of_Quarter
FROM cteSNAP;
