# Overview

**DISCLAIMER**: All data and analysis results stored or produced by this repo do not involve
real data. They are not to be interpreted in support of any real-world position or opinion.

This repo contains a sample analysis I performed as a Research Analyst at the
University of Chicago [Crime Lab](https://crimelab.uchicago.edu/) and [Education Lab](https://educationlab.uchicago.edu/). The analysis predicts out-of-school suspension days using a random forest machine learning model and investigates
the causal effect of an education intervention on out-of-school suspensions for students with high versus
low amounts of predicted suspensions. You can find a description of each task in this repo
below.

# Task Descriptions

This repo contains four tasks. In order:

1. `simulate_data`: simulates a high school and elementary school
student-year level dataset from 2009 to 2019. This simulated data is used in all following tasks.

2. `predict_suspensions`: uses 8th grade outcomes (arrests, GPA, etc.) and student covariates
(race, gender, etc.) to predict out-of-school suspensions for all students in 2013 (the year prior
to the education intervention).

3. `run_did`: runs the difference-in-differences estimator of Chaisemartin and d'Haultfoueille [(2024)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3731856) to estimate the causal effect
of the intervention on out-of-school suspension days.

4. `generate_report`: produces a pdf report that summarizes the estimation results from
the difference-in-differences estimator. A figure from this report is reproduced below.


![](https://github.com/bryantco/rp-portfolio/blob/main/_assets/oss_days_q4.png)

# Setup Instructions

In your terminal:

1. Create the `conda` environment: `conda create -f disruption_env.yaml`

2. Run all tasks via the main `makefile`: `make all`
