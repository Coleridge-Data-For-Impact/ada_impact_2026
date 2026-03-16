-- Add "blank" person dimension record (ONLY RUN ONCE)
/*
INSERT INTO DIM_Person (Person_Key, Person_UID, Date_of_Birth, Gender, Ethnicity_American_Indian_or_Alaska_Native,
                              Ethnicity_Asian, Ethnicity_Black_or_African_American, Ethnicity_Hispanic_or_Latino,
                              Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander, Ethnicity_White, Ethnicity_Other)
VALUES (0, '', CAST('9999-01-01' AS DATE), '', '', '', '', '', '', '', '');
*/

-- Add new person dimension records
INSERT INTO DIM_Person (Person_Key, Person_UID, Date_of_Birth, Gender, Ethnicity_American_Indian_or_Alaska_Native,
                   Ethnicity_Asian, Ethnicity_Black_or_African_American, Ethnicity_Hispanic_or_Latino,
                   Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander, Ethnicity_White, Ethnicity_Other)
SELECT	mdm.Person_Master_ID,
        mdm.Person_UID,
		mdm.Date_of_Birth,
		mdm.Gender,
		mdm.Ethnicity_American_Indian_or_Alaska_Native,
		mdm.Ethnicity_Asian,
		mdm.Ethnicity_Black_or_African_American,
		mdm.Ethnicity_Hispanic_or_Latino,
		mdm.Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander,
		mdm.Ethnicity_White,
		mdm.Ethnicity_Other
FROM tr_e2e.MDM_Person_Master mdm
LEFT JOIN DIM_Person dim
	ON mdm.Person_Master_ID = dim.Person_Key
WHERE dim.Person_Key IS NULL;

-- Update changed person dimension records
UPDATE DIM_Person
SET Date_of_Birth = mdm.Date_of_Birth,
    Gender = mdm.Gender,
    Ethnicity_American_Indian_or_Alaska_Native = mdm.Ethnicity_American_Indian_or_Alaska_Native,
    Ethnicity_Asian = mdm.Ethnicity_Asian,
    Ethnicity_Black_or_African_American = mdm.Ethnicity_Black_or_African_American,
    Ethnicity_Hispanic_or_Latino = mdm.Ethnicity_Hispanic_or_Latino,
    Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander = mdm.Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander,
    Ethnicity_White = mdm.Ethnicity_White,
    Ethnicity_Other = mdm.Ethnicity_Other
FROM tr_e2e.MDM_Person_Master mdm
INNER JOIN DIM_Person dim
	ON mdm.Person_Master_ID = dim.Person_Key
WHERE (dim.Date_of_Birth <> mdm.Date_of_Birth
    OR dim.Gender <> mdm.Gender
    OR dim.Ethnicity_American_Indian_or_Alaska_Native <> mdm.Ethnicity_American_Indian_or_Alaska_Native
    OR dim.Ethnicity_Asian <> mdm.Ethnicity_Asian
    OR dim.Ethnicity_Black_or_African_American <> mdm.Ethnicity_Black_or_African_American
    OR dim.Ethnicity_Hispanic_or_Latino <> mdm.Ethnicity_Hispanic_or_Latino
    OR dim.Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander <> mdm.Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander
    OR dim.Ethnicity_White <> mdm.Ethnicity_White
    OR dim.Ethnicity_Other <> mdm.Ethnicity_Other);
