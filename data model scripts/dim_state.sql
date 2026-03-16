-- Add "blank" State dimension record (ONLY RUN ONCE)
/*
INSERT INTO DIM_State (State_Key, State_FIPS_Code, State_Abbreviation, State_Name)
VALUES (0, '', '', '');
*/

INSERT INTO DIM_State (State_Key, State_FIPS_Code, State_Abbreviation, State_Name)
SELECT mdm.State_ID, mdm.State_FIPS_Code, mdm.State_Abbreviation, mdm.State_Name
FROM tr_e2e.MDM_State mdm
LEFT JOIN DIM_State dim
    ON mdm.State_ID = dim.State_Key
WHERE dim.State_Key IS NULL;
