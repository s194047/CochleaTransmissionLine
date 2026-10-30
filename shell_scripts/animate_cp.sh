#!/usr/bin/env bash
set -euo pipefail

export IC_DURATION=100
export FREQUENCY=1000

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

ONSET_RAMP_TIME=0.100
DURATION=10
AMPLITUDE=1

for roughness in rough no_rough; do
    for variable in y v; do
        STIMULUS_SINE_DIR="frequency-${FREQUENCY}__duration-${DURATION}__onset_ramp_time-${ONSET_RAMP_TIME}__ic_duration-${IC_DURATION}__roughness-${roughness}__saveat-2e-5__only_save_last_interval"
        STIMULUS_SINE_SUFFIX="${STIMULUS_SINE_DIR}__amplitude-${AMPLITUDE}"
        STIMULUS_ZERO_SUFFIX="stimulus_zero_initial_${IC_DURATION}s_${roughness}"

    julia --project=. scripts/plotting_scripts/animate_cp.jl \
        -i "${DATA_DIR}/stimulus_sine/${STIMULUS_SINE_DIR}/${STIMULUS_SINE_SUFFIX}.jld2" \
        -o ${FIGURE_DIR}/cp_animation/stimulus_sine/${STIMULUS_SINE_DIR}/${STIMULUS_SINE_SUFFIX}__${variable}.gif \
        -p 5 \
        -v ${variable} &

    julia --project=. scripts/plotting_scripts/animate_cp.jl \
        -i "${DATA_DIR}/stimulus_zero/${STIMULUS_ZERO_SUFFIX}.jld2" \
        -o ${FIGURE_DIR}/cp_animation/stimulus_zero/${STIMULUS_ZERO_SUFFIX}__${variable}.gif \
        -p 5 \
        -f ${FREQUENCY} \
        -v ${variable} &
    done
done

wait
