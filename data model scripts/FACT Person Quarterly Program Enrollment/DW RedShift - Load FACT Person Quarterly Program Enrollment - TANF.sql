/*
This script will load the FACT Person Quarterly Program Enrollment table with data for the "Temporary Assistance for Needy Families (TANF)" program.
    Step 1
        Find reporting months that only have a spell end record.
        Data is returned in the cteSpellEnd common table expression (CTE).
    Step 2
        Find spell start and end months for each person.  If a record has both the start_of_spell and end_of_spell flags set to true then the entry and exit months
        are set to the reporting_month.  If the record only has start_of_spell set to true, then the nearest reporting_month for the same person in cteSpellEnd is used
        as the exit month.  Note that if there are two or more overlapping spell ranges with different end months, then one or more of the spells could have the wrong end month.
        The results of this step are returned in the cteTANFSpell CTE.
    Step 3
        Reporting months are mapped to their corresponding quarter and a qtr_month_flag is created to identify which months in the quarter were enrolled.
        The qtr_month_flag is the decimal representation of a binary number where each bit in the binary represents a month.  The first (left most) bit is
        used to represent the first month of the quarter and the third (right most) bit is used for the third month.  The results are grouped on person
        and quarter and the binary month flags are summed together to create the qtr_month_flag which will have a decimal value between
        1 (binary 001) and 7 (binary 111).
        The results are returned in the cteTANF CTE which should contain one record for each person and quarter that had an enrollment.
    Step 4
        This step looks up the dimension keys for the person and program.  The qtr_month_flag is used to calculate the Enrolled_Entire_Quarter, 
        Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, and Enrolled_Third_Month_of_Quarter indicators.  The results will include
        all quarters for each enrollment period a person might have.
        The results of this step are inserted into the fact table..
*/

-- FACT Person Quarterly Program Enrollment (TANF)
INSERT INTO tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment (Person_Key, Program_Key, enrollment_year_quarter_key, Enrolled_Entire_Quarter,
                                                      Enrolled_First_Month_of_Quarter, Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
WITH cteSpellEnd (social_security_number, reporting_month)
AS
(
    --If the start of spell flag is off and the end of spell flag is on, then the reporting month is when the spell ended.
    --These end of spell reporting months will be matched to spell starts in the cteTANFSpell query below. 
    SELECT DISTINCT social_security_number, reporting_month
    FROM ds_ar_dhs.tanf_member
    WHERE tanf_start_of_spell = 'FALSE'
    AND tanf_end_of_spell = 'TRUE'
    AND LEFT(reporting_month, 4) >= '2010'
    AND LEN(tanf_member.reporting_month) = 6
    AND valid_ssn_format = 'Y'
),
cteTANFSpell (social_security_number, entry_month, exit_month)
AS
(
    -- If the start and end of spell flags are both turned on, then the entry and exit months are the reporting month.
    SELECT  tm.social_security_number, tm.reporting_month, tm.reporting_month
    FROM ds_ar_dhs.tanf_member tm
    WHERE tm.tanf_start_of_spell = 'TRUE'
    AND tm.tanf_end_of_spell = 'TRUE'
    AND LEFT(tm.reporting_month, 4) >= '2010'
    AND LEN(tm.reporting_month) = 6
    AND tm.valid_ssn_format = 'Y'
    UNION
    --If the start of spell flag is on and the end of spell flag is off, then we have to find the nearest spell end in cteSpellEnd.
    --WARNING: If there are two overlapping spells with different end months for the same person, then one of the spells could end up using the wrong end date.
    --      Example 1: If spell #1 ran from February 2022 thru June 2022 and spell #2 ran from March 2022 thru September 2022 
    --                 then spell #1 will be correct but spell #2 will incorrectly end in June 2022 rather than September 2022
    --                    because June 2022 is the min date that is greater than March 2022.
    --      Example 2: If spell #1 ran from February 2022 thru September 2022 and spell #2 ran from March 2022 thru June 2022 
    --                 then spell #2 will be correct but spell #1 will incorrectly end in June 2022 rather than September 2022
    --                    because June 2022 is the min date that is greater than March 2022.
    SELECT  ts.social_security_number,
            ts.reporting_month,
            CASE
                WHEN MIN(cteSpellEnd.reporting_month) IS NULL THEN CAST('999901' AS CHAR(6))
                ELSE MIN(cteSpellEnd.reporting_month)
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
),
cteTANF (social_security_number, enrollment_year_quarter_key, qtr_month_flag)
AS
(
    SELECT  cteTANFSpell.social_security_number,
            qtr.Year_Quarter_Key,
            --Decimal representation of a binary flag where the 1st, 2nd, and 3rd month of the quarter are identified as separate bits and added together to create a bitmask.
            --Example 1: If only enrolled in the 2nd month of the quarter, then the 2nd bit will be turned on. [010 (binary) equals 2 (decimal)]
            --Example 2: If enrolled in the 2nd and 3rd months of the quarter, then the 2nd and 3rd bits will be turned on.  [010 + 100 = 110 (binary) equals 6 (decimal)]
            SUM(CASE 
                    WHEN RIGHT(tanf_member.reporting_month, 2) IN ('01', '04', '07', '10') THEN 1  --equals 001 binary
                    WHEN RIGHT(tanf_member.reporting_month, 2) IN ('02', '05', '08', '11') THEN 2  --equals 010 binary
                    WHEN RIGHT(tanf_member.reporting_month, 2) IN ('03', '06', '09', '12') THEN 4  --equals 100 binary
                END) AS qtr_month_flag
    FROM cteTANFSpell
    INNER JOIN ds_ar_dhs.tanf_member
        ON tanf_member.reporting_month BETWEEN cteTANFSpell.entry_month AND cteTANFSpell.exit_month
    INNER JOIN tr_state_impact_ada_training.DIM_Year_Quarter qtr
        ON TO_DATE(CONCAT(tanf_member.reporting_month, CAST('01' AS CHAR(2))), 'YYYYMMDD') BETWEEN qtr.Quarter_Start_Date and qtr.Quarter_End_Date
    GROUP BY cteTANFSpell.social_security_number, qtr.Year_Quarter_Key
)
SELECT DISTINCT
        --Lookup Person Surrogate Key
        (
            SELECT DIM_Person.Person_Key
            FROM tr_state_impact_ada_training.DIM_Person
            WHERE DIM_Person.Person_UID = cteTANF.social_security_number
        ) AS Person_Key,
        --Lookup Program Surrogate Key
        (
            SELECT DIM_Program.Program_Key
            FROM tr_state_impact_ada_training.DIM_Program
            WHERE DIM_Program.Program_Name = 'Temporary Assistance for Needy Families (TANF)'
        ) AS Program_Key,
        cteTANF.enrollment_year_quarter_key,
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
FROM cteTANF;
