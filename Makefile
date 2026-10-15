PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: sim compile

sim:
	mkdir -p "$(PROJECT_DIR)work"
	cd "$(PROJECT_DIR)work" && xrun -F "$(PROJECT_DIR)files.f"

compile:
	mkdir -p "$(PROJECT_DIR)work"
	cd "$(PROJECT_DIR)work" && xrun -elaborate -F "$(PROJECT_DIR)files.f"
