-- Add "blank" CIP dimension record (ONLY RUN ONCE)
/*
INSERT INTO DIM_CIP (CIP_Key, Classification_Code, Classification_Name, Category_Name,
                     Series_Name, Series_Short_Name, Major_Group_Code, Major_Group_Name)
VALUES (0, '', '', '', '', '', '', '');
*/


-- Add new CIP code dimension records
INSERT INTO DIM_CIP (CIP_Key, Classification_Code, Classification_Name, Category_Name,
                     Series_Name, Series_Short_Name, Major_Group_Code, Major_Group_Name)
SELECT  mdm.CIP_ID, mdm.Classification_Code, mdm.Classification_Name, mdm.Category_Name,
        mdm.Series_Name, mdm.Series_Short_Name, mdm.Major_Group_Code, mdm.Major_Group_Name
FROM tr_e2e.MDM_CIP mdm
LEFT JOIN DIM_CIP dim
    ON mdm.CIP_ID = dim.CIP_Key
WHERE dim.CIP_Key IS NULL;

-- Update changed CIP code dimension records
UPDATE DIM_CIP
SET Classification_Name = mdm.Classification_Name
    Category_Name = mdm.Category_Name
    Series_Name = mdm.Series_Name
    Series_Short_Name = mdm.Series_Short_Name
    Major_Group_Code = mdm.Major_Group_Code
    Major_Group_Name = mdm.Major_Group_Name
FROM tr_e2e.MDM_CIP mdm
INNER JOIN DIM_CIP dim
    ON mdm.CIP_ID = dim.CIP_Key
WHERE mdm.Classification_Name <> dim.Classification_Name
    OR mdm.Category_Name <> dim.Category_Name
    OR mdm.Series_Name <> dim.Series_Name
    OR mdm.Series_Short_Name <> dim.Series_Short_Name
    OR mdm.Major_Group_Code <> dim.Major_Group_Code
    OR mdm.Major_Group_Name <> dim.Major_Group_Name;
