-- Add new year/quarter dimension records
INSERT INTO DIM_Year_Quarter (Year_Quarter_Key, Calendar_Year, Calendar_Quarter, Quarter_Start_Date, Quarter_End_Date)
SELECT	mdm.Year_Quarter_ID,
        mdm.Calendar_Year,
        mdm.Calendar_Quarter,
        mdm.Quarter_Start_Date,
        mdm.Quarter_End_Date
FROM tr_e2e.MDM_Year_Quarter mdm
LEFT JOIN DIM_Year_Quarter dim
	ON mdm.Year_Quarter_ID = dim.Year_Quarter_Key
WHERE dim.Year_Quarter_Key IS null
group by 1,2,3,4,5;
