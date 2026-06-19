#!/usr/bin/env zsh
set -euo pipefail

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

for freq_type in winding rotation; do
    for roughness in rough no_rough; do
        for ic_duration in 5 20 100; do
            julia --project=. scripts/plotting_scripts/plot_osc_frequencies.jl \
            -i ${DATA_DIR}/stimulus_zero/stimulus_zero_initial_${ic_duration}s_${roughness}.jld2 \
            -o ${FIGURE_DIR}/ic_roughness_comparison/${freq_type}_${roughness}_${ic_duration}s.pdf \
            -f ${freq_type} -x length
        done
    done
done
