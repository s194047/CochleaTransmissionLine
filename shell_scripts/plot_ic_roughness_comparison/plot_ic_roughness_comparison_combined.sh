#!/usr/bin/env zsh
set -euo pipefail
for orientation in horizontal vertical; do
    for freq_type in winding rotation; do
        julia --project=. scripts/plotting_scripts/plot_osc_frequencies_ic_roughness_combined.jl \
        -i data/stimulus_zero \
        -o data/figures/ic_roughness_comparison/${freq_type}_combined_${orientation}.pdf \
        -O ${orientation} \
        -f ${freq_type} \
        -x length &
    done
done

wait
