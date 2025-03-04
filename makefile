CURRENT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: all clean

all:
	cd simulate_data && make all
	cd predict_suspensions && make all
	cd run_did && make all
	cd generate_report && make all
	
clean:
	cd simulate_data && make clean
	cd predict_suspensions && make clean
	cd run_did && make clean
	cd generate_report && make clean
	
