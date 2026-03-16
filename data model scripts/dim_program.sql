-- Add new program dimension records
INSERT INTO tr_state_impact_ada_training.DIM_Program (Program_Key, Program_Name)
SELECT	mdm.Program_ID,
        mdm.Program_Name
FROM tr_e2e.MDM_Program mdm
LEFT JOIN tr_state_impact_ada_training.DIM_Program dim
	ON mdm.Program_ID = dim.Program_Key
WHERE dim.Program_Key IS null
group by 1,2;