CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir = $(CURRENT_DIR)/output

# Inputs
df_es = ../simulate_data/output/df_es.parquet
df_hs = ../simulate_data/output/df_hs.parquet
config = $(CURRENT_DIR)/hand/config.yaml

code_generate_features = $(CURRENT_DIR)/src/generate_features.py
code_predict = $(CURRENT_DIR)/src/predict.py

# Outputs
df_hs_for_rf = $(CURRENT_DIR)/output/df_hs_for_rf.parquet
df_hs_predicted_oss = $(CURRENT_DIR)/output/df_hs_predicted_oss.parquet

all: $(df_hs_for_rf) $(df_hs_predicted_oss)

$(df_hs_for_rf): $(df_es) $(df_hs) $(code_generate_features) $(config)
	mkdir -p $(output_dir)
	python3 $(code_generate_features) \
		--df_es=$(df_es) \
		--df_hs=$(df_hs) \
		--config=$(config) \
		--df_hs_for_rf=$(df_hs_for_rf)

$(df_hs_predicted_oss): $(df_hs_for_rf) $(code_predict) $(config)
	python3 $(code_predict) \
		--df_hs_for_rf=$(df_hs_for_rf) \
		--config=$(config) \
		--df_hs_predicted_oss=$(df_hs_predicted_oss)
		
clean: 
	rm -rf $(output_dir)
