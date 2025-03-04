CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir = $(CURRENT_DIR)/output

# Inputs
code_simulate_data = $(CURRENT_DIR)/src/simulate_data.R

# Outputs
df_hs = $(CURRENT_DIR)/output/df_hs.parquet
df_es = $(CURRENT_DIR)/output/df_es.parquet

all: $(df_es)

$(df_es): $(code_simulate_data)
	mkdir -p $(output_dir)
	/opt/R/4.1.3/bin/Rscript $(code_simulate_data) \
		--df_hs=$(df_hs) \
		--df_es=$(df_es) \
		--output_dir=$(output_dir)
		
clean:
	rm -rf $(output_dir)
