
GRANT SELECT ON TABLE tr_state_impact_ada_training.DIM_cip TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.DIM_cip TO group db_t00141_rw;

GRANT SELECT ON TABLE tr_state_impact_ada_training.DIM_Person TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.DIM_Person TO group db_t00141_rw;

GRANT SELECT ON TABLE tr_state_impact_ada_training.DIM_Program TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.DIM_Program TO group db_t00141_rw;

GRANT SELECT ON TABLE tr_state_impact_ada_training.DIM_Year_Quarter TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.DIM_Year_Quarter TO group db_t00141_rw;

GRANT SELECT ON TABLE tr_state_impact_ada_training.DIM_County TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.DIM_County TO group db_t00141_rw;


GRANT SELECT ON TABLE  tr_state_impact_ada_training.dim_state  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.dim_state TO group db_t00141_rw;

GRANT SELECT ON TABLE  tr_state_impact_ada_training.nb_analysis_frame  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.nb_analysis_frame  TO group db_t00141_rw;


GRANT SELECT ON TABLE  tr_state_impact_ada_training.fact_person_program_participation  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.fact_person_program_participation  TO group db_t00141_rw;

GRANT UPDATE, SELECT, DELETE, REFERENCES ON TABLE tr_state_impact_ada_training.FACT_Person_Program_Start_End TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, REFERENCES ON TABLE tr_state_impact_ada_training.FACT_Person_Program_Start_End TO group db_t00141_rw;


GRANT UPDATE, SELECT, DELETE, REFERENCES ON TABLE tr_state_impact_ada_training.fact_person_program_outcome  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, REFERENCES ON TABLE tr_state_impact_ada_training.fact_person_program_outcome  TO group db_t00141_rw;


GRANT SELECT ON TABLE tr_state_impact_ada_training.FACT_Person_UI_Wage TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.FACT_Person_UI_Wage TO group db_t00141_rw;

GRANT SELECT ON TABLE tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.FACT_Person_Quarterly_Program_Enrollment TO group db_t00141_rw;


GRANT SELECT ON TABLE tr_state_impact_ada_training.fact_person_program_observation_quarter  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.fact_person_program_observation_quarter  TO group db_t00141_rw;


GRANT SELECT ON TABLE  tr_state_impact_ada_training.ci_wioa_coenroll TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.ci_wioa_coenroll TO group db_t00141_rw;

GRANT SELECT ON TABLE  tr_state_impact_ada_training.ci_promis_cohort  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.ci_promis_cohort  TO group db_t00141_rw;

GRANT SELECT ON TABLE  tr_state_impact_ada_training.nb_cohort  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.nb_cohort  TO group db_t00141_rw;


GRANT SELECT ON TABLE  tr_state_impact_ada_training.fact_person_quarterly_program_enrollment  TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE tr_state_impact_ada_training.fact_person_quarterly_program_enrollment  TO group db_t00141_rw;


/*
GRANT SELECT ON TABLE DIM_Intake_Characteristics TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE DIM_Intake_Characteristics TO group db_t00141_rw;


GRANT SELECT ON TABLE FACT_Person_Quarterly_Program_Enrollment TO group ci_read_group;
GRANT UPDATE, SELECT, DELETE, INSERT ON TABLE FACT_Person_Quarterly_Program_Enrollment TO group db_t00141_rw;*/