using Glob
using FilePaths
using JLD2
using TimeZones
using DataInterpolations
using CairoMakie
using Statistics
using DSP

"""
    oscillator_winding_frequency(t, u)

Takes a time vector and a matrix where the first axis is the time axis and the second axis is the oscillator index.
One oscillator is two columns representing displacement `y` and velocity `v`, respectively.

A winding means the state revolves 2π around the origin in phase space.

Returns the winding frequency for each osicllator as a vector.
"""
function oscillator_winding_frequency(
    t::Vector{Float64},
    u::Matrix{Float64}
)::Vector{Float64}
    y, v = @views u[:, 1:2:end], u[:, 2:2:end]
    θ = unwrap(atan.(v, y), dims=1)
    Δθ = θ[end, :] - θ[1, :]
    Δt = t[end] - t[1]
    Δθ ./ Δt
end

"""
    oscillator_rotation_frequency(t, u)

Takes a time vector and a matrix where the first axis is the time axis and the second axis is the oscillator index.
One oscillator is two columns representing displacement `y` and velocity `v`, respectively.

A rotation means the curvature in phase space is 2π regardless of whether it is around the origin or not.

Returns the rotation frequency for each osicllator as a vector.
"""
function oscillator_rotation_frequency(
    t::Vector{Float64},
    u::Matrix{Float64}
)::Vector{Float64}
    du = diff(u, dims=1)
    dy, dv = @views du[:, 1:2:end], du[:, 2:2:end]
    θ = unwrap(atan.(dv, dy), dims=1)
    Δθ = θ[end, :] - θ[1, :]
    Δt = t[end-1] - t[1] # due to diff being one shorter, we consider the second-to-last element of t as well
    Δθ ./ Δt
end

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
