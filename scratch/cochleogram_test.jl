using CochleaTransmissionLine

using Glob
using FilePaths
using JLD2
using TimeZones
using DataInterpolations
using CairoMakie

# Load files containing CTL outputs
n_files = 5
speech_commands_processed_root = "/Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01_up_down_yes_no_output/jld2"
subdir = "yes"
files_to_load = glob("*.jld2", joinpath(speech_commands_processed_root, subdir))[1:n_files]
println(stderr, "List of files to load:")
for file in files_to_load
    println(stderr, "$file")
end

# Process each file in time windows
fs_resampled = 50e3 # 50 kHz
window_length_seconds = 0.020
window_hop_seconds = 0.010

window_rms_values_list = Vector{Union{Missing, Matrix{Float64}}}(missing, n_files)
for (file, file_idx) in zip(files_to_load, 1:n_files)
    println(stderr, "Loading file: $file")
    t, u, metadata = load(file, "t", "u", "metadata")

    interpolator = CubicSpline(stack(u, dims=2), t)

    t_start = t[1]
    t_end = t[end]
    t_resampled = collect(t_start:1/fs_resampled:t_end)
    u_resampled = stack(interpolator.(t_resampled), dims=1)

    n_samples = size(u_resampled, 1)
    window_length_samples = Int(window_length_seconds*fs_resampled)
    window_hop_samples = Int(window_hop_seconds*fs_resampled)
    window_start_idxs = 1:window_hop_samples:(n_samples-window_length_samples)

    window_rms_values = zeros(length(window_start_idxs), size(u_resampled, 2) ÷ 2)
    println(stderr, "Processing the data in $(length(window_start_idxs)) windows.")
    for (window_start_idx, window_column_idx) in zip(window_start_idxs, 1:length(window_start_idxs))
        window_end_idx = window_start_idx + window_length_samples - 1 # Julia slices are [inclusive:inclusive], so we subtract the last index by one
        println(stderr, "window: ($window_start_idx, $window_end_idx)")
        u_windowed = u_resampled[window_start_idx:window_end_idx, :]
        window_rms_values[window_column_idx, :] = oscillator_rms(u_windowed)
    end
    window_rms_values_list[file_idx] = window_rms_values
end

for plot_idx in 1:length(window_rms_values_list)
    win_idxs = 1:size(window_rms_values_list[plot_idx], 1)
    osc_idxs = 100:900

    time_values = (win_idxs .- 1) * window_hop_seconds

    fig = Figure()
    ax = Axis(fig[1, 1])

    hm = heatmap!(
        ax,
        time_values,
        osc_idxs,
        window_rms_values_list[plot_idx][win_idxs, osc_idxs],
        colorrange = (1e-9, 5e-8),
    )

    ax.xlabel = "Time / s"
    ax.ylabel = "Oscillator Index"
    ax.yreversed = true

    cb = Colorbar(fig[1, 2], hm)

    display(fig)
end
