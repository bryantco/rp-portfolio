CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Inputs
report_qmd = $(CURRENT_DIR)/report.qmd
code_render_report = $(CURRENT_DIR)/src/render_report.R

# Outputs
report_pdf = $(CURRENT_DIR)/report.pdf

all: $(report_pdf)

$(report_pdf): $(report_qmd) $(code_render_report)
	Rscript $(code_render_report) \
		--report_qmd=$(report_qmd)
		
clean:
	rm $(report_pdf)