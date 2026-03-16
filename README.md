# State IMPACT Applied Data Analytics 2025–2026

Class materials for the [Coleridge Initiative](https://coleridgeinitiative.org) Applied Data Analytics training delivered as part of the **[State IMPACT Collaborative](https://coleridgeinitiative.org/state-impact-collaborative)**.

The published book is available at: **https://coleridge-initiative.github.io/ada_impact_2026/**

## About the State IMPACT Collaborative

The State IMPACT (Innovative Models for Policy Acceleration & Collaborative Testing) Collaborative is a partnership between the Coleridge Initiative and [MDRC](https://www.mdrc.org/work/projects/state-impact-collaborative) that strengthens state agencies' capacity for rigorous program evaluation. The collaborative brings together state and local agency staff, MDRC researchers, and Coleridge data scientists in a "learning-by-doing" model, working on workforce development, higher education, income support, housing, and justice policy questions.

## Repository Contents

### Notebooks
Step-by-step analytical notebooks covering the full evaluation workflow:

| Notebook | Topic |
|---|---|
| 01 | Exploratory Data Analysis |
| 02 | Introduction to the Data Model and Cross-Sectional Analysis |
| 03 | Measurement of Wage Outcomes for a Cohort |
| 03a | Understanding the Data Model Tables |
| 04 | Applied Regression Analysis |
| 05 | Propensity Score Matching |
| 06 | Exports |
| 07 | Difference-in-Differences Analysis |

### Data Model Scripts
SQL scripts for building the dimensional data model underlying the analysis, organized by table type:
- DDL and dimension table setup
- Analytic framework and cohort creation
- FACT tables: Quarterly Program Enrollment, Program Participation, Outcomes, Observation Quarter, UI Wage

### Supplemental
- Package installation guide
- Imputation illustration

## Building the Book

The book is built with [Quarto](https://quarto.org) and published automatically to GitHub Pages on push to `main` via GitHub Actions.

To render locally:
```bash
quarto preview
```

## License

© 2026 The Coleridge Initiative, Inc
