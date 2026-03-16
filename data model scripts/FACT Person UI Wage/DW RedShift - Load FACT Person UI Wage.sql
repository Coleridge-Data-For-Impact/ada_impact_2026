-- FACT Person UI Wage
INSERT INTO FACT_Person_UI_Wage (Person_Key, Year_Quarter_Key, UI_Quarterly_Wages)
SELECT p.Person_Key, qtr.Year_Quarter_Key, sum(lehd.employee_wage_amount)
FROM ds_ar_dws.ui_wages_lehd lehd
INNER JOIN DIM_Person p
    ON lehd.employee_ssn = p.Person_UID
INNER JOIN DIM_Year_Quarter qtr
    ON lehd.reporting_period_year = qtr.Calendar_Year
    AND lehd.reporting_period_quarter = qtr.Calendar_Quarter
WHERE lehd.reporting_period_year >= '2010'
GROUP BY p.Person_Key, qtr.Year_Quarter_Key;
