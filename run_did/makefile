CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir = $(CURRENT_DIR)/output

# Inputs
df_hs_predicted_oss = $(CURRENT_DIR)/../predict_suspensions/output/df_hs_predicted_oss.parquet
config = $(CURRENT_DIR)/hand/config.yaml

code_run_did = $(CURRENT_DIR)/src/run_did.R
task_utils = $(CURRENT_DIR)/src/utils.R
code_general_utils = $(CURRENT_DIR)/../utils/utils.R

# Outputs
results_rds = $(CURRENT_DIR)/output/results.rds
results_xlsx = $(CURRENT_DIR)/output/results.xlsx
oss_days_q4 = $(CURRENT_DIR)/output/oss_days_q4.png

all: $(oss_days_q4)

$(oss_days_q4): $(code_run_did) $(df_hs_predicted_oss) $(config) $(task_utils)
	Rscript $(code_run_did) \
		--df_hs_predicted_oss=$(df_hs_predicted_oss) \
		--config=$(config) \
		--task_utils=$(task_utils) \
		--results_rds=$(results_rds) \
		--results_xlsx=$(results_xlsx) \
		--oss_days_q4=$(oss_days_q4) \
		--output_dir=$(output_dir)
		
clean: 
	rm -rf $(output_dir)

