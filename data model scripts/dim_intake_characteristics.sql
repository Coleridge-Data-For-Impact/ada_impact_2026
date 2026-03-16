-- Add "blank" Intake Characteristics dimension record (ONLY RUN ONCE)
/*
INSERT INTO DIM_Intake_Characteristics (Intake_Characteristics_Key, Highest_School_Grade_Completed_at_Program_Entry,
                                Highest_Education_Level_Completed_at_Program_Entry, School_Status_at_Program_Entry,
                                Employment_Status_at_Program_Entry, Long_Term_Unemployment_at_Program_Entry,
                                Exhausting_TANF_Within_2_Yrs_at_Program_Entry, Foster_Care_Youth_Status_at_Program_Entry,
                                Homeless_or_Runaway_at_Program_Entry, Ex_Offender_Status_at_Program_Entry, Low_Income_Status_at_Program_Entry,
                                English_Language_Learner_at_Program_Entry, Low_Levels_of_Literacy_at_Program_Entry,
                                Cultural_Barriers_at_Program_Entry, Single_Parent_at_Program_Entry, Displaced_Homemaker_at_Program_Entry)
VALUES (0, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '');
*/

-- Add new Intake Characteristics records
INSERT INTO DIM_Intake_Characteristics (Intake_Characteristics_Key, Highest_School_Grade_Completed_at_Program_Entry,
                                Highest_Education_Level_Completed_at_Program_Entry, School_Status_at_Program_Entry,
                                Employment_Status_at_Program_Entry, Long_Term_Unemployment_at_Program_Entry,
                                Exhausting_TANF_Within_2_Yrs_at_Program_Entry, Foster_Care_Youth_Status_at_Program_Entry,
                                Homeless_or_Runaway_at_Program_Entry, Ex_Offender_Status_at_Program_Entry, Low_Income_Status_at_Program_Entry,
                                English_Language_Learner_at_Program_Entry, Low_Levels_of_Literacy_at_Program_Entry,
                                Cultural_Barriers_at_Program_Entry, Single_Parent_at_Program_Entry, Displaced_Homemaker_at_Program_Entry)
SELECT  mdm.Intake_Characteristics_Master_ID,
        mdm.Highest_School_Grade_Completed_at_Program_Entry,
        mdm.Highest_Education_Level_Completed_at_Program_Entry,
        mdm.School_Status_at_Program_Entry,
        mdm.Employment_Status_at_Program_Entry,
        mdm.Long_Term_Unemployment_at_Program_Entry,
        mdm.Exhausting_TANF_Within_2_Yrs_at_Program_Entry,
        mdm.Foster_Care_Youth_Status_at_Program_Entry,
        mdm.Homeless_or_Runaway_at_Program_Entry,
        mdm.Ex_Offender_Status_at_Program_Entry,
        mdm.Low_Income_Status_at_Program_Entry,
        mdm.English_Language_Learner_at_Program_Entry,
        mdm.Low_Levels_of_Literacy_at_Program_Entry,
        mdm.Cultural_Barriers_at_Program_Entry,
        mdm.Single_Parent_at_Program_Entry,
        mdm.Displaced_Homemaker_at_Program_Entry
FROM tr_e2e.MDM_Intake_Characteristics_Master mdm
LEFT JOIN DIM_Intake_Characteristics dim
    ON mdm.Intake_Characteristics_Master_ID = dim.Intake_Characteristics_Key
WHERE dim.Intake_Characteristics_Key IS NULL
AND NOT(mdm.Highest_School_Grade_Completed_at_Program_Entry = ''
        AND mdm.Highest_Education_Level_Completed_at_Program_Entry = ''
        AND mdm.School_Status_at_Program_Entry = ''
        AND mdm.Employment_Status_at_Program_Entry = ''
        AND mdm.Long_Term_Unemployment_at_Program_Entry = ''
        AND mdm.Exhausting_TANF_Within_2_Yrs_at_Program_Entry = ''
        AND mdm.Foster_Care_Youth_Status_at_Program_Entry = ''
        AND mdm.Homeless_or_Runaway_at_Program_Entry = ''
        AND mdm.Ex_Offender_Status_at_Program_Entry = ''
        AND mdm.Low_Income_Status_at_Program_Entry = ''
        AND mdm.English_Language_Learner_at_Program_Entry = ''
        AND mdm.Low_Levels_of_Literacy_at_Program_Entry = ''
        AND mdm.Cultural_Barriers_at_Program_Entry = ''
        AND mdm.Single_Parent_at_Program_Entry = ''
        AND mdm.Displaced_Homemaker_at_Program_Entry = '');