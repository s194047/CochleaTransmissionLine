#!/usr/bin/env bash
set -euo pipefail

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

for x_type in length; do #index; do
    # Zero stimulus matrices
    julia --project=. ./scripts/plotting_scripts/mutual_information/plot_mutual_information.jl \
        -i ${DATA_DIR}/mutual_information/mutual_information__stimulus_zero_initial_100s_rough.jld2 \
        -x ${x_type} \
        -o ${FIGURE_DIR}/mutual_information/mutual_information__stimulus_zero_initial_100s_rough_${x_type}.pdf &

    # Sine stimulus matrices
    julia --project=. ./scripts/plotting_scripts/mutual_information/plot_mutual_information.jl \
        -i ${DATA_DIR}/mutual_information/mutual_information__stimulus_sine_1000_initial_100s_rough_amplitude-1.jld2 \
        -x ${x_type} \
        -o ${FIGURE_DIR}/mutual_information/mutual_information__stimulus_sine_1000_initial_100s_rough_amplitude-1_${x_type}.pdf &
done

wait
