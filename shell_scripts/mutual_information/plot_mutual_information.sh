#!/usr/bin/env bash
set -euo pipefail

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

: "${GAMMA:=0.5}"
: "${X_TYPE:=length}"

# Zero stimulus matrix
julia --project=. ./scripts/plotting_scripts/mutual_information/plot_mutual_information.jl \
    -i ${DATA_DIR}/mutual_information/mutual_information__stimulus_zero_initial_100s_rough.jld2 \
    -x ${X_TYPE} \
    -g ${GAMMA} \
    -o ${FIGURE_DIR}/mutual_information/mutual_information__stimulus_zero_initial_100s_rough.pdf &

# Sine stimulus matrix
julia --project=. ./scripts/plotting_scripts/mutual_information/plot_mutual_information.jl \
    -i ${DATA_DIR}/mutual_information/mutual_information__stimulus_sine_1000_initial_100s_rough_amplitude-1__only_last_1s.jld2 \
    -x ${X_TYPE} \
    -g ${GAMMA} \
    -o ${FIGURE_DIR}/mutual_information/mutual_information__stimulus_sine_1000_initial_100s_rough_amplitude-1__only_last_1s.pdf &

wait
