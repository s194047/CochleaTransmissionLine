#!/usr/bin/env zsh
set -euo pipefail

for freq_type in winding rotation; do
    julia --project=. scripts/plotting_scripts/plot_osc_frequencies_ic_roughness_combined.jl \
    -i data/stimulus_zero \
    -o data/figures/ic_roughness_comparison/${freq_type}_combined.pdf \
    -f ${freq_type} -x length
done
