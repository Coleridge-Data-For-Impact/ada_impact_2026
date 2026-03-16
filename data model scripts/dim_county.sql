-- Add "blank" county dimension record (ONLY RUN ONCE)
/*
INSERT INTO DIM_County (County_Key, County_FIPS_Code, County_Name, Rural_Urban_Continuum, Local_Workforce_Development_Area)
VALUES (0, '', '', '', '');
*/

-- Add new county dimension records
INSERT INTO DIM_County (County_Key, County_FIPS_Code, County_Name, Rural_Urban_Continuum, Local_Workforce_Development_Area)
SELECT  mdm.County_ID,
        mdm.County_FIPS_Code,
        mdm.County_Name,
        mdm.Rural_Urban_Continuum,
        mdm.Local_Workforce_Development_Area
FROM tr_e2e.MDM_County mdm
LEFT JOIN DIM_County dim
    ON mdm.County_ID = dim.County_Key
WHERE dim.County_KEY IS NULL;

-- Update changed county dimension records
UPDATE DIM_County
SET County_Name = county.name,
    Rural_Urban_Continuum = ruc.name,
    Local_Workforce_Development_Area = county.local_workforce_development_area
FROM tr_e2e.MDM_County mdm
INNER JOIN DIM_County dim
    ON mdm.County_ID = dim.County_Key
WHERE mdm.County_Name <> dim.County_Name
    OR mdm.Rural_Urban_Continuum <> dim.Rural_Urban_Continuum
    OR mdm.Local_Workforce_Development_Area <> dim.Local_Workforce_Development_Area;
