#!/bin/sh

set -e
set -o pipefail

# : "${SPL_TARGET:=60.0}"
: "${IC_DURATION:=100}"
: "${ROUGHNESS:=rough}"
: "${SAVEAT:=2e-5}"

: "${TOTAL_FILES:=700}"
: "${PARALLELISM:=16}"

export IC_DURATION ROUGHNESS SAVEAT TOTAL_FILES PARALLELISM

for SPL_TARGET in 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0
do
    SPL_TARGET=$SPL_TARGET TOTAL_FILES=$((TOTAL_FILES * 4)) \
        bsub < shell_scripts/plot_cochleogram_data/plot_cochleogram_data_hpc.sh
done

SPL_TARGET=60.0 ROUGHNESS=no_rough TOTAL_FILES=$((TOTAL_FILES * 4)) \
    bsub < shell_scripts/plot_cochleogram_data/plot_cochleogram_data_hpc.sh

SPL_TARGET=60.0 ROUGHNESS=no_rough IC_DURATION=5 SAVEAT=no TOTAL_FILES=$((TOTAL_FILES * 4)) \
    bsub < shell_scripts/plot_cochleogram_data/plot_cochleogram_data_hpc.sh
