/*==============================================================*/
/* DBMS name:      Amazon Redshift Database                     */
/* Created on:     9/7/2023 12:14:46 PM                         */
/*==============================================================*/


drop table FACT_Person_Program_Observation_Quarter;

drop table FACT_Person_Program_Outcome;

drop table FACT_Person_Program_Participation;

drop table FACT_Person_UI_Wage;

drop table FACT_Person_Quarterly_Program_Enrollment;

drop table DIM_CIP;

drop table DIM_County;

drop table DIM_Intake_Characteristics;

drop table DIM_Person;

drop table DIM_Program;

drop table DIM_State;

drop table DIM_Year_Quarter;


/*==============================================================*/
/* Table: DIM_CIP                                               */
/*==============================================================*/
create table if not exists DIM_CIP (
   CIP_Key BIGINT not null,
   Classification_Code CHAR(7) not null,
   Classification_Name VARCHAR(300) not null,
   Category_Name VARCHAR(300) not null,
   Series_Name VARCHAR(300) not null,
   Series_Short_Name VARCHAR(300) not null,
   Major_Group_Code CHAR(2) not null,
   Major_Group_Name VARCHAR(300) not null,
   constraint DIM_CIP_PK_IDX primary key (CIP_Key),
    unique (Classification_Code)
);

/*==============================================================*/
/* Table: DIM_County                                            */
/*==============================================================*/
create table if not exists DIM_County (
   County_Key BIGINT not null,
   County_FIPS_Code CHAR(5) not null,
   County_Name VARCHAR(150) not null,
   Rural_Urban_Continuum VARCHAR(300) not null,
   Local_Workforce_Development_Area VARCHAR(30) not null,
   constraint DIM_COUNTY_PK_IDX primary key (County_Key),
    unique (County_FIPS_Code)
);

/*==============================================================*/
/* Table: DIM_Intake_Characteristics                            */
/*==============================================================*/
create table if not exists DIM_Intake_Characteristics (
   Intake_Characteristics_Key BIGINT not null,
   Highest_School_Grade_Completed_at_Program_Entry VARCHAR(2) not null,
   Highest_Education_Level_Completed_at_Program_Entry VARCHAR(100) not null,
   School_Status_at_Program_Entry VARCHAR(100) not null,
   Employment_Status_at_Program_Entry VARCHAR(100) not null,
   Long_Term_Unemployment_at_Program_Entry VARCHAR(3) not null,
   Exhausting_TANF_Within_2_Yrs_at_Program_Entry VARCHAR(3) not null,
   Foster_Care_Youth_Status_at_Program_Entry VARCHAR(3) not null,
   Homeless_or_Runaway_at_Program_Entry VARCHAR(3) not null,
   Ex_Offender_Status_at_Program_Entry VARCHAR(3) not null,
   Low_Income_Status_at_Program_Entry VARCHAR(3) not null,
   English_Language_Learner_at_Program_Entry VARCHAR(3) not null,
   Low_Levels_of_Literacy_at_Program_Entry VARCHAR(3) not null,
   Cultural_Barriers_at_Program_Entry VARCHAR(3) not null,
   Single_Parent_at_Program_Entry VARCHAR(3) not null,
   Displaced_Homemaker_at_Program_Entry VARCHAR(3) not null,
   constraint DIM_INTAKE_CHARACTERISTICS_PK_IDX primary key (Intake_Characteristics_Key)
);

/*==============================================================*/
/* Table: DIM_Person                                            */
/*==============================================================*/
create table if not exists DIM_Person (
   Person_Key BIGINT not null,
   Person_UID CHAR(64) not null,
   Date_of_Birth DATE not null,
   Gender VARCHAR(10) not null,
   Ethnicity_American_Indian_or_Alaska_Native VARCHAR(3) not null,
   Ethnicity_Asian VARCHAR(3) not null,
   Ethnicity_Black_or_African_American VARCHAR(3) not null,
   Ethnicity_Hispanic_or_Latino VARCHAR(3) not null,
   Ethnicity_Native_Hawaiian_or_Other_Pacific_Islander VARCHAR(3) not null,
   Ethnicity_White VARCHAR(3) not null,
   Ethnicity_Other VARCHAR(3) not null,
   constraint DIM_PERSON_PK_IDX primary key (Person_Key),
    unique (Person_UID)
);

/*==============================================================*/
/* Table: DIM_Program                                           */
/*==============================================================*/
create table if not exists DIM_Program (
   Program_Key INTEGER not null,
   Program_Name VARCHAR(75) not null,
   constraint DIM_PROGRAM_PK_IDX primary key (Program_Key),
    unique (Program_Name)
);

/*==============================================================*/
/* Table: DIM_State                                             */
/*==============================================================*/
create table if not exists DIM_State (
   State_Key INTEGER not null,
   State_FIPS_Code CHAR(2) not null,
   State_Abbreviation CHAR(2) not null,
   State_Name VARCHAR(50) not null,
   constraint DIM_STATE_PK_IDX primary key (State_Key),
    unique (State_FIPS_Code),
    unique (State_Abbreviation)
);

/*==============================================================*/
/* Table: DIM_Year_Quarter                                      */
/*==============================================================*/
create table if not exists DIM_Year_Quarter (
   Year_Quarter_Key INTEGER not null,
   Calendar_Year CHAR(4) not null,
   Calendar_Quarter CHAR(1) not null,
   Quarter_Start_Date DATE not null,
   Quarter_End_Date DATE not null,
   constraint DIM_YEAR_QUARTER_PK_IDX primary key (Year_Quarter_Key),
    unique (Calendar_Year, Calendar_Quarter)
);

/*==============================================================*/
/* Table: FACT_Person_Program_Observation_Quarter               */
/*==============================================================*/
create table if not exists FACT_Person_Program_Observation_Quarter (
   Person_Program_Observation_Quarter_ID BIGINT not null identity,
   Person_Key BIGINT not null,
   Program_Key INTEGER not null,
   Observation_Year_Quarter_Key INTEGER not null,
   County_of_Residence_Key BIGINT not null,
   State_of_Residence_Key INTEGER not null,
   CIP_Classification_Key BIGINT not null,
   Enrolled_Entire_Quarter VARCHAR(3) not null,
   Enrolled_First_Month_of_Quarter VARCHAR(3) not null,
   Enrolled_Second_Month_of_Quarter VARCHAR(3) not null,
   Enrolled_Third_Month_of_Quarter VARCHAR(3) not null,
   Gross_Monthly_Income DECIMAL(14,2),
   Net_Monthly_Income DECIMAL(14,2),
   Date_of_Most_Recent_Career_Service DATE,
   Received_Training VARCHAR(3) not null,
   Eligible_Training_Provider_Name VARCHAR(75) not null,
   Eligible_Training_Provider_Program_of_Study VARCHAR(100) not null,
   Date_Entered_Training_1 DATE,
   Type_of_Training_Service_1 VARCHAR(100) not null,
   Date_Entered_Training_2 DATE,
   Type_of_Training_Service_2 VARCHAR(100) not null,
   Date_Entered_Training_3 DATE,
   Type_of_Training_Service_3 VARCHAR(100) not null,
   Participated_in_Postsecondary_Education_During_Program_Participation VARCHAR(3) not null,
   Received_Training_from_Private_Section_Operated_Program VARCHAR(3) not null,
   Enrolled_in_Secondary_Education_Program VARCHAR(3) not null,
   Date_Enrolled_in_Post_Exit_Education_or_Training_Program DATE,
   Youth_2nd_Quarter_Placement VARCHAR(50),
   Youth_4th_Quarter_Placement VARCHAR(50),
   Other_Reason_for_Exit VARCHAR(50) not null,
   Migrant_and_Seasonal_Farmworker_Status VARCHAR(50) not null,
   Individual_with_a_Disability VARCHAR(3) not null,
   Zip_Code_of_Residence CHAR(5) not null,
   Higher_Education_Student_Level VARCHAR(100) not null,
   Higher_Education_Enrollment_Status VARCHAR(100) not null,
   Higher_Education_Tuition_Status VARCHAR(100) not null,
   constraint FACT_PERSON_PROGRAM_OBSERVATION_QUARTER_PK_IDX primary key (Person_Program_Observation_Quarter_ID),
    unique (Person_Key, Program_Key, Observation_Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_PERSON foreign key (Person_Key) 
      references DIM_Person (Person_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_PROGRAM foreign key (Program_Key) 
      references DIM_Program (Program_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_YEAR_QUARTER foreign key (Observation_Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_COUNTY foreign key (County_of_Residence_Key) 
      references DIM_County (County_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_STATE foreign key (State_of_Residence_Key) 
      references DIM_State (State_Key),
   constraint FK_FACT_PERSON_PROGRAM_OBSERVATION_QUARTER__DIM_CIP foreign key (CIP_Classification_Key) 
      references DIM_CIP (CIP_Key)
);

/*==============================================================*/
/* Table: FACT_Person_Program_Outcome                           */
/*==============================================================*/
create table if not exists FACT_Person_Program_Outcome (
   Person_Program_Outcomes_ID BIGINT not null identity,
   Person_Key BIGINT not null,
   Program_Key INTEGER not null,
   Exit_Year_Quarter_Key INTEGER not null,
   Employed_in_1st_Quarter_After_Exit_Quarter VARCHAR(30) not null,
   Type_of_Employment_Match_1st_Quarter_After_Exit_Quarter VARCHAR(50) not null,
   Earnings_1st_Quarter_After_Exit_Quarter DECIMAL(9,2),
   Employed_in_2nd_Quarter_After_Exit_Quarter VARCHAR(30) not null,
   Type_of_Employment_Match_2nd_Quarter_After_Exit_Quarter VARCHAR(50) not null,
   Earnings_2nd_Quarter_After_Exit_Quarter DECIMAL(9,2),
   Employed_in_3rd_Quarter_After_Exit_Quarter VARCHAR(30) not null,
   Type_of_Employment_Match_3rd_Quarter_After_Exit_Quarter VARCHAR(50) not null,
   Earnings_3rd_Quarter_After_Exit_Quarter DECIMAL(9,2),
   Employed_in_4th_Quarter_After_Exit_Quarter VARCHAR(30) not null,
   Type_of_Employment_Match_4th_Quarter_After_Exit_Quarter VARCHAR(50) not null,
   Earnings_4th_Quarter_After_Exit_Quarter DECIMAL(9,2),
   Employment_Related_to_Training VARCHAR(3),
   Retention_with_Same_Employer_2nd_Quarter_and_4th_Quarter VARCHAR(3) not null,
   Type_of_Recognized_Credential_1 VARCHAR(100) not null,
   Type_of_Recognized_Credential_2 VARCHAR(100) not null,
   Type_of_Recognized_Credential_3 VARCHAR(100) not null,
   Date_Attained_Recognized_Credential_1 DATE,
   Date_Attained_Recognized_Credential_2 DATE,
   Date_Attained_Recognized_Credential_3 DATE,
   Date_of_Most_Recent_Measurable_Skill_Gain_Educational_Functional_Level DATE,
   Date_of_Most_Recent_Measurable_Skill_Gain_Postsecondary_Transcript DATE,
   Date_of_Most_Recent_Measurable_Skill_Gain_Secondary_Transcript DATE,
   Date_of_Most_Recent_Measurable_Skill_Gain_Training_Milestone DATE,
   Date_of_Most_Recent_Measurable_Skill_Gain_Skills_Progression DATE,
   Date_Enrolled_in_Education_or_Training_Program_Leading_to_Credential_or_Employment DATE,
   Date_Completed_an_Education_or_Training_Program_Leading_to_Credential_or_Employment DATE,
   Date_Attained_Graduate_or_Post_Graduate_Degree DATE,
   constraint FACT_PERSON_PROGRAM_OUTCOME_PK_IDX primary key (Person_Program_Outcomes_ID),
    unique (Person_Key, Program_Key, Exit_Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_OUTCOME__DIM_PERSON foreign key (Person_Key) 
      references DIM_Person (Person_Key),
   constraint FK_FACT_PERSON_PROGRAM_OUTCOME__DIM_PROGRAM foreign key (Program_Key) 
      references DIM_Program (Program_Key),
   constraint FK_FACT_PERSON_PROGRAM_OUTCOME__DIM_YEAR_QUARTER foreign key (Exit_Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key)
);

/*==============================================================*/
/* Table: FACT_Person_Program_Participation                     */
/*==============================================================*/
create table if not exists FACT_Person_Program_Participation (
   Person_Program_Participation_ID BIGINT not null identity,
   Person_Key BIGINT not null,
   Intake_Characteristics_Key BIGINT not null,
   Program_Key INTEGER not null,
   Entry_Year_Quarter_Key INTEGER not null,
   Exit_Year_Quarter_Key INTEGER not null,
   County_of_Residence_Key BIGINT not null,
   State_of_Residence_Key INTEGER not null,
   CIP_Classification_Key BIGINT not null,
   Gross_Monthly_Income DECIMAL(14,2),
   Net_Monthly_Income DECIMAL(14,2),
   Date_of_Most_Recent_Career_Service DATE,
   Received_Training VARCHAR(3) not null,
   Eligible_Training_Provider_Name VARCHAR(75) not null,
   Eligible_Training_Provider_Program_of_Study VARCHAR(100) not null,
   Date_Entered_Training_1 DATE,
   Type_of_Training_Service_1 VARCHAR(100) not null,
   Date_Entered_Training_2 DATE,
   Type_of_Training_Service_2 VARCHAR(100) not null,
   Date_Entered_Training_3 DATE,
   Type_of_Training_Service_3 VARCHAR(100) not null,
   Participated_in_Postsecondary_Education_During_Program_Participation VARCHAR(3) not null,
   Received_Training_from_Private_Section_Operated_Program VARCHAR(3) not null,
   Enrolled_in_Secondary_Education_Program VARCHAR(3) not null,
   Date_Enrolled_in_Post_Exit_Education_or_Training_Program DATE,
   Youth_2nd_Quarter_Placement VARCHAR(50),
   Youth_4th_Quarter_Placement VARCHAR(50),
   Incarcerated_at_Program_Entry VARCHAR(3) not null,
   Date_Released_from_Incarceration DATE,
   Other_Reason_for_Exit VARCHAR(50) not null,
   Migrant_and_Seasonal_Farmworker_Status VARCHAR(50) not null,
   Individual_with_a_Disability VARCHAR(3) not null,
   Zip_Code_of_Residence CHAR(5) not null,
   Higher_Education_Student_Level VARCHAR(100) not null,
   Higher_Education_Enrollment_Status VARCHAR(100) not null,
   Higher_Education_Tuition_Status VARCHAR(100) not null,
   constraint FACT_PERSON_PROGRAM_PARTICIPATION_PK_IDX primary key (Person_Program_Participation_ID),
    unique (Person_Key, Program_Key, Entry_Year_Quarter_Key, Exit_Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_PROGRAM foreign key (Program_Key) 
      references DIM_Program (Program_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_YEAR_QUARTER__ENTRY_YEAR foreign key (Entry_Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_PERSON foreign key (Person_Key) 
      references DIM_Person (Person_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_YEAR_QUARTER__EXIT_YEAR foreign key (Exit_Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_INTAKE_CHARACTERISTICS foreign key (Intake_Characteristics_Key) 
      references DIM_Intake_Characteristics (Intake_Characteristics_Key),
   constraint FK_FACT_PERSON_PROGRAM_PARTICIPATION__DIM_COUNTY foreign key (County_of_Residence_Key) 
      references DIM_County (County_Key),
   constraint FK_FACT_PERSON_PROGRAM__FACT_PERSON_PROGRAM_PARTICIPATION__DIM_CIP_DIM_CIP foreign key (CIP_Classification_Key) 
      references DIM_CIP (CIP_Key),
   constraint FK_FACT_PERSON_PROGRAM__FACT_PERSON_PROGRAM_PARTICIPATION__DIM_STATE_DIM_STATE foreign key (State_of_Residence_Key) 
      references DIM_State (State_Key)
);

/*==============================================================*/
/* Table: FACT_Person_UI_Wage                                   */
/*==============================================================*/
create table if not exists FACT_Person_UI_Wage (
   Person_UI_Wage_ID BIGINT not null identity,
   Person_Key BIGINT not null,
   Year_Quarter_Key INTEGER not null,
   UI_Quarterly_Wages DECIMAL(10,0) not null,
   constraint FACT_PERSON_UI_WAGE_PK_IDX primary key (Person_UI_Wage_ID),
    unique (Person_Key, Year_Quarter_Key),
   constraint FK_FACT_PERSON_UI_WAGE__DIM_PERSON foreign key (Person_Key) 
      references DIM_Person (Person_Key),
   constraint FK_FACT_PERSON_UI_WAGE__DIM_YEAR_QUARTER foreign key (Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key)
);

/*==============================================================*/
/* Table: FACT_Person_Quarterly_Program_Enrollment              */
/*==============================================================*/
create table if not exists FACT_Person_Quarterly_Program_Enrollment (
   Person_Quarterly_Program_Enrollment_ID BIGINT not null identity,
   Person_Key BIGINT ,
   Program_Key INTEGER not null,
   Enrollment_Year_Quarter_Key INTEGER not null,
   Enrolled_Entire_Quarter VARCHAR(3) not null,
   Enrolled_First_Month_of_Quarter VARCHAR(3) not null,
   Enrolled_Second_Month_of_Quarter VARCHAR(3) not null,
   Enrolled_Third_Month_of_Quarter VARCHAR(3) not null,
   constraint PK_FACT_Person_Quarterly_Program_Enrollment primary key (Person_Quarterly_Program_Enrollment_ID),
    unique (Person_Key, Program_Key, Enrollment_Year_Quarter_Key),
   constraint FK_FACT_PERSON_QUARTERLY_PROGRAM_ENROLLMENT_DIM_PROGRAM foreign key (Program_Key) 
      references DIM_Program (Program_Key),
   constraint FK_FACT_PERSON_QUARTERLY_PROGRAM_ENROLLMENT_DIM_YEAR_QUARTER foreign key (Enrollment_Year_Quarter_Key) 
      references DIM_Year_Quarter (Year_Quarter_Key),
   constraint FK_FACT_PERSON_QUARTERLY_PROGRAM_ENROLLMENT_DIM_PERSON foreign key (Person_Key) 
     references DIM_Person (Person_Key)
);
