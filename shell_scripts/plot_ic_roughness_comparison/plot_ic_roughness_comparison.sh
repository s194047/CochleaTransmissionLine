#!/usr/bin/env zsh
set -euo pipefail

for freq_type in winding rotation; do
    for roughness in rough no_rough; do
        for ic_duration in 5 20 100; do
            julia --project=. scripts/plotting_scripts/plot_osc_frequencies.jl \
            -i data/stimulus_zero/stimulus_zero_initial_${ic_duration}s_${roughness}.jld2 \
            -o data/figures/ic_roughness_comparison/${freq_type}_${roughness}_${ic_duration}s.pdf \
            -f ${freq_type} -x length
        done
    done

    julia --project=. scripts/plotting_scripts/plot_osc_frequencies_ic_roughness_combined.jl \
    -i data/stimulus_zero \
    -o data/figures/ic_roughness_comparison/${freq_type}_combined.pdf \
    -f ${freq_type} -x length
done
