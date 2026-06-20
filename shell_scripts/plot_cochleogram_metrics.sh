#!/usr/bin/env bash
set -euo pipefail

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

: "${COLUMN_WIDTH:=221.0}"

RUN_ID=spl_target-60.0__spl_reference-0.001__ic_duration-100__roughness-rough__saveat-2e-5

COCHLEOGRAM_ID=yes/0bd689d7_nohash_0__${RUN_ID}__window_length-0.020s__window_hop-0.010s

scripts/plotting_scripts/plot_cochleogram_data.py \
-i ${DATA_DIR}/speech_commands_v0.01_up_down_yes_no/output/${RUN_ID}/cochleogram/data/${COCHLEOGRAM_ID}.hdf5 \
-o ${FIGURE_DIR}/cochleogram_metrics/${COCHLEOGRAM_ID}.pdf \
-w ${COLUMN_WIDTH}
