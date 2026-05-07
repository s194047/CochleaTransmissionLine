using CochleaTransmissionLine

using Glob
using FilePaths
using JLD2
using TimeZones
using DataInterpolations
using CairoMakie
using Statistics

# Load file containing CTL outputs
# speech_commands_processed_root = "/Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01_up_down_yes_no_output/jld2"
# subdir = "yes"
# file = glob("*.jld2", joinpath(speech_commands_processed_root, subdir))[1]

file = "/Users/sofus/Documents/DTU/MSc_project/cochleatransmissionline.jl/data/sine_1000Hz_60dB_1s.jld2"

println(stderr, "Loading file: $file")
t, u, metadata = load(file, "t", "u", "metadata")
u = stack(u, dims=1)

begin
    osc_idx = 800
    y, v = @views u[:, 1:2:end], u[:, 2:2:end]

    f = Figure()
    ax = Axis(f[1, 1])
    lines!(ax, y[:, osc_idx], v[:, osc_idx])
    display(f)
end

@show oscillator_winding_frequency(t, u)[[1; 500; 800]]
@show oscillator_rotation_frequency(t, u)[[1; 500; 800]]
