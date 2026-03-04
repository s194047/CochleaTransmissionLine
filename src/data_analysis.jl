using DataInterpolations
using DSP

function interpolate_signal(
    t::Vector{Float64},
    u::Vector{Vector{Float64}},
    sample_rate::Float64,
    ;
    compute_derivative::Bool=false,
    ignore_seconds_start::Float64=0.0,
    ignore_seconds_end::Float64=0.0,
)
    t_values = t[1] + ignore_seconds_start : 1/sample_rate : t[end] - ignore_seconds_end
    interpolator = CubicSpline(u, t, cache_parameters=true)

    u_values = stack(interpolator(t_values), dims=1)

    if compute_derivative
        du_values = stack([
            DataInterpolations.derivative(interpolator, t_value)
            for t_value ∈ t_values
        ], dims=1)

        (; t_values, u_values, du_values)
    else
        (; t_values, u_values)
    end
end

function instantaneous_rotation(z::Matrix{ComplexF64}, dz::Matrix{ComplexF64})
    @. abs(imag(conj(z) * dz)) / abs2(z)
end
function instantaneous_rotation(u::Matrix{Float64}, du::Matrix{Float64})
    u1, u2 = @views u[:, 1:2:end], u[:, 2:2:end]
    du1, du2 = @views du[:, 1:2:end], du[:, 2:2:end]

    z = u1 + im * u2
    dz = du1 + im * du2

    instantaneous_rotation(z, dz)
end

"""
    mean_rotation

Calculate the mean rotation number of `n` where two columns of `u` gives one point in the phase space of an oscillator.
The number of columns in `u` is `2n`. `t` is the time vector.
"""
function mean_rotation(
    t::Vector{Float64},
    u::Matrix{Float64},
    ;
    idx_interval::Union{Tuple{Int64, Int64}, Nothing}=nothing,
    scale_by_rms::Bool=false,
)
    if !isnothing(idx_interval)
        start_idx, end_idx = idx_interval
        t = t[start_idx:end_idx]
        u = u[start_idx:end_idx, :]
    end

    if scale_by_rms
        u = scaled_by_rms(u)
    end

    z = @views u[:, 1:2:end] + im * u[:, 2:2:end]

    angle_values = unwrap(angle.(z), dims=1)
    total_angle = angle_values[end, :] - angle_values[1, :]
    total_time = t[end] - t[1]

    total_angle / total_time
end

"""
    time_to_idx(t, t_interval)

Convert times to indices in a sorted array `t` of time values.
"""
function time_to_idx(
    t::AbstractVector{<:Real},
    t_interval::Tuple{<:Real,<:Real},
)
    ntuple(i -> searchsortedfirst(t, t_interval[i]), 2)
end

"""
    scale_by_rms

Scale each column of `u` by 1 / sqrt(2) / rms. If all columns are sinusoidal, this results in scaling them to amplitude 1.
This is useful for phase-space analysis to make phase portraits more circular.
"""
function scaled_by_rms(u::Matrix{Float64})
    scaling_factors = 1 / sqrt(2) ./ rms(u, dims=1)
    u .* scaling_factors
end
