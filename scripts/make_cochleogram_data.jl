using CochleaTransmissionLine

using JLD2
using TimeZones
using HDF5
using DataInterpolations
using Statistics
using DSP
using ArgParse

input_file_opt = "input-file"
output_file_opt = "output-file"
sample_rate_opt = "sample-rate"
window_length_seconds_opt = "window-length-seconds"
window_hop_seconds_opt = "window-hop-seconds"

function parse_commandline()::Dict
    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--$input_file_opt", "-i"], Dict(
            :help => "JLD2 file containing the DDE solution of the CTL.",
            :arg_type => String,
            :metavar => "FILENAME",
            :required => true,
        ),
        ["--$output_file_opt", "-o"], Dict(
            :help => "Output HDF5 file containing the processed cochleogram data.",
            :arg_type => String,
            :metavar => "FILENAME",
            :required => true,
        ),
        ["--$sample_rate_opt", "-s"], Dict(
            :help => "Sample rate for the interpolation of the input data. Should be left blank if the signal shouldn't be resampled.",
            :arg_type => Float64,
            :metavar => "SAMPLE_RATE",
        ),
        ["--$window_length_seconds_opt", "-l"], Dict(
            :help => "Window length in seconds.",
            :arg_type => Float64,
            :metavar => "LENGTH",
            :required => true,
        ),
        ["--$window_hop_seconds_opt", "-p"], Dict(
            :help => "Window hop in seconds.",
            :arg_type => Float64,
            :metavar => "LENGTH",
            :required => true,
        ),
    )

    parse_args(arg_defs)
end

function main()
    start_time = now(localzone())
    parsed_args = parse_commandline()

    input_filename        = parsed_args[input_file_opt]
    output_filename       = parsed_args[output_file_opt]
    fs                    = get(parsed_args, sample_rate_opt, nothing)
    window_length_seconds = parsed_args[window_length_seconds_opt]
    window_hop_seconds    = parsed_args[window_hop_seconds_opt]

    println(stderr, "Input file:                $input_filename")
    println(stderr, "Output file:               $output_filename")
    println(stderr, "Interpolation sample rate: $fs")
    println(stderr, "Window length:             $window_length_seconds s")
    println(stderr, "Window hop:                $window_hop_seconds s")

    println(stderr, "Loading JLD2 file with CTL solution.")
    t, u, ctl_metadata = load(input_filename, "t", "u", "metadata")

    if isnothing(fs)
        println(stderr, "No sample rate specified. Solution will not be resampled. Assuming uniform sampling periods.")
        t_resampled, u_resampled = t, stack(u, dims=1)
        fs = (length(t) - 1) / (t[end] - t[1])
        println(stderr, "Extracted sample rate from time vector: $fs")
    else
        println(stderr, "Resampling the solution.")
        u_stacked = stack(u, dims=1)
        interpolator = CubicSpline(u_stacked', t)
        t_resampled = collect(t[1]:1/fs:t[end])
        u_resampled = stack(interpolator.(t_resampled), dims=1)
    end

    n_samples = size(u_resampled, 1)
    window_length_samples = Int(window_length_seconds * fs)
    window_hop_samples = Int(window_hop_seconds * fs)
    window_start_idxs = collect(1:window_hop_samples:(n_samples - window_length_samples))

    window_rms_values                = zeros(length(window_start_idxs), size(u_resampled, 2) ÷ 2)
    window_winding_frequency_values  = zeros(length(window_start_idxs), size(u_resampled, 2) ÷ 2)
    window_rotation_frequency_values = zeros(length(window_start_idxs), size(u_resampled, 2) ÷ 2)
    println(stderr, "Processing the data in $(length(window_start_idxs)) windows.")
    for (window_start_idx, window_column_idx) in zip(window_start_idxs, 1:length(window_start_idxs))
        window_end_idx = window_start_idx + window_length_samples - 1 # Julia slices are [inclusive:inclusive], so we subtract the last index by one
        println(stderr, "window: ($window_start_idx, $window_end_idx)")
        t_windowed = t_resampled[window_start_idx:window_end_idx]
        u_windowed = u_resampled[window_start_idx:window_end_idx, :]
        window_rms_values[window_column_idx, :]                = oscillator_rms(u_windowed)
        window_winding_frequency_values[window_column_idx, :]  = oscillator_winding_frequency(t_windowed, u_windowed)
        window_rotation_frequency_values[window_column_idx, :] = oscillator_rotation_frequency(t_windowed, u_windowed)
    end

    println(stderr, "Creating metadata dictionary.")
    metadata = Dict(
        "start_time"            => string(start_time),
        "input_filename"        => input_filename,
        "output_filename"       => output_filename,
        "fs"                    => fs,
        "window_length_seconds" => window_length_seconds,
        "window_hop_seconds"    => window_hop_seconds,
        "ctl_metadata"          => ctl_metadata,
    )

    println(stderr, "Writing the processed data in to $output_filename.")
    mkpath(dirname(output_filename))
    h5open(output_filename, "w") do output_file
        output_file["n_samples"]                        = n_samples
        output_file["window_length_samples"]            = window_length_samples
        output_file["window_hop_samples"]               = window_hop_samples
        output_file["window_start_idxs"]                = window_start_idxs
        output_file["window_rms_values"]                = window_rms_values
        output_file["window_winding_frequency_values"]  = window_winding_frequency_values
        output_file["window_rotation_frequency_values"] = window_rotation_frequency_values
        meta = create_group(file, "metadata")
        attrs = attributes(meta)
        for (k, v) in metadata
            attrs[k] = v
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
