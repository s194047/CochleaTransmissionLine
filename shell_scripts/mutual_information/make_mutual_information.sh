#!/usr/bin/env bash
set -euo pipefail

: "${DATA_DIR:=data}"

STIMULUS_SINE_ID=frequency-1000__duration-10__onset_ramp_time-0.100__ic_duration-100__roughness-rough__saveat-2e-5__only_save_last_interval
STIMULUS_SINE_SHORT_ID=stimulus_sine_1000_initial_100s_rough

for exp_x2 in {-6..6}; do
    amplitude=$(awk "BEGIN {print 10^($exp_x2/2)}")
    julia --project=. -t 10 scripts/plotting_scripts/mutual_information/make_mutual_information.jl \
        -i ${DATA_DIR}/stimulus_sine/${STIMULUS_SINE_ID}/${STIMULUS_SINE_ID}__amplitude-${amplitude}.jld2 \
        -o ${DATA_DIR}/mutual_information/mutual_information/stimulus_sine/${STIMULUS_SINE_SHORT_ID}__amplitude-${amplitude}.jld2
done
