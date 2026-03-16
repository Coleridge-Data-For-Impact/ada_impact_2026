/*==============================================================*/
/* Table: FACT_Person_Quarterly_Program_Enrollment              */
/*==============================================================*/

drop table tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment;

CREATE TABLE  tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment AS
WITH ctePirl (program_name, social_security_number, entry_date, exit_date) AS
(
    -- Adult
    SELECT 'Adult (WIOA)'::varchar(75)        AS program_name,
           social_security_number,
           date_of_program_entry_wioa         AS entry_date,
           MAX(date_of_program_exit_wioa)     AS exit_date
    FROM ds_ar_dws.pirl_update a
    WHERE DATEPART(year, date_of_program_entry_wioa) >= 2010
      AND valid_ssn_format = 'Y'
      AND adult_wioa IN (1,2,3)
      AND a.sheetnameproperty = 'Adult'
    GROUP BY social_security_number, date_of_program_entry_wioa

    UNION ALL

    -- Dislocated Worker
    SELECT 'Dislocated Worker (WIOA)'::varchar(75),
           social_security_number,
           date_of_program_entry_wioa,
           MAX(date_of_program_exit_wioa)
    FROM ds_ar_dws.pirl_update a
    WHERE DATEPART(year, date_of_program_entry_wioa) >= 2010
      AND valid_ssn_format = 'Y'
      AND dislocated_worker_wioa IN (1,2,3)
      AND a.sheetnameproperty = 'Dislocated Worker'
    GROUP BY social_security_number, date_of_program_entry_wioa

    UNION ALL

    -- Wagner–Peyser
    SELECT 'Wagner-Peyser Employment Service (WIOA)'::varchar(75),
           social_security_number,
           date_of_program_entry_wioa,
           MAX(date_of_program_exit_wioa)
    FROM ds_ar_dws.pirl_update a
    WHERE DATEPART(year, date_of_program_entry_wioa) >= 2010
      AND valid_ssn_format = 'Y'
      AND wagner_peyser_employment_service_wioa = 1
      AND a.sheetnameproperty = 'Wagner-Peyser'
    GROUP BY social_security_number, date_of_program_entry_wioa
), 

cteQuarterRange (program_name, social_security_number, entry_quarter_key, exit_quarter_key, min_entry_date, max_exit_date)
AS
(
    SELECT  ctePirl.program_name,
            ctePirl.social_security_number,
            entry_qtr.Year_Quarter_Key,
            exit_qtr.Year_Quarter_Key,
            MIN(ctePirl.entry_date) AS min_entry_date,
            MAX(COALESCE(ctePirl.exit_date, GETDATE())) AS max_exit_date
    FROM ctePirl
    INNER JOIN tr_state_impact_ada_training.DIM_Year_Quarter entry_qtr
        ON ctePirl.entry_date BETWEEN entry_qtr.quarter_start_date AND entry_qtr.quarter_end_date     
    INNER JOIN tr_state_impact_ada_training.DIM_Year_Quarter exit_qtr
        ON COALESCE(ctePirl.exit_date, GETDATE()) BETWEEN exit_qtr.quarter_start_date and exit_qtr.quarter_end_date
    GROUP BY ctePirl.program_name, ctePirl.social_security_number, entry_qtr.Year_Quarter_Key, exit_qtr.Year_Quarter_Key
),
cteFactData (Person_Key, Program_Key, Enrollment_Year_Quarter_Key, Enrolled_First_Month_of_Quarter,
             Enrolled_Second_Month_of_Quarter, Enrolled_Third_Month_of_Quarter)
AS
(
    SELECT DISTINCT
            --Lookup Person Surrogate Key
            (
                SELECT DIM_Person.Person_Key
                FROM tr_state_impact_ada_training.DIM_Person
                WHERE DIM_Person.Person_UID = cteQuarterRange.social_security_number
            ) AS Person_Key,
            --Lookup Program Surrogate Key
            (
                SELECT DIM_Program.Program_Key
                FROM tr_state_impact_ada_training.DIM_Program
                WHERE DIM_Program.Program_Name = cteQuarterRange.program_name
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
    INNER JOIN tr_state_impact_ada_training.DIM_Year_Quarter qtr
        ON qtr.Year_Quarter_Key BETWEEN cteQuarterRange.entry_quarter_key AND cteQuarterRange.exit_quarter_key
)
SELECT  Person_Key,
        Program_Key,
        Enrollment_Year_Quarter_Key,
        CASE
            WHEN MAX(Enrolled_First_Month_of_Quarter) = 'Yes' AND MAX(Enrolled_Second_Month_of_Quarter) = 'Yes' AND MAX(Enrolled_Third_Month_of_Quarter) = 'Yes' THEN 'Yes'
            ELSE 'No'
        END AS Enrolled_Entire_Quarter,
        MAX(Enrolled_First_Month_of_Quarter) as  Enrolled_First_Month_of_Quarter,
        MAX(Enrolled_Second_Month_of_Quarter) as  Enrolled_Second_Month_of_Quarter,
        MAX(Enrolled_Third_Month_of_Quarter) as  Enrolled_Third_Month_of_Quarter
FROM cteFactData
GROUP BY Person_Key, Program_Key, Enrollment_Year_Quarter_Key
order BY Person_Key, Program_Key, Enrollment_Year_Quarter_Key;


GRANT SELECT ON TABLE tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment TO group db_t00141_rw;
