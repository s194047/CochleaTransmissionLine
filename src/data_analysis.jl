using SciMLBase: ODESolution
using Statistics
using DSP

function get_solution_samples(solution::ODESolution, t::Vector{Float64}, deriv=Val{0}; idxs=nothing)
    x = stack(solution(t, deriv, idxs=idxs).u, dims=1)
    t, x
end
function get_solution_samples(solution::ODESolution, fs::Float64, deriv=Val{0}; idxs=nothing)
    t_start, t_end = solution.t[1], solution.t[end]
    t = collect(t_start:1/fs:t_end)
    get_solution_samples(solution, t, deriv, idxs=idxs)
end

function instantaneous_rotation(z::Matrix{ComplexF64}, dz::Matrix{ComplexF64})
    @. abs(imag(conj(z) * dz)) / abs2(z)
end
function instantaneous_rotation(x::Matrix{Float64}, dx::Matrix{Float64})
    x1, x2 = @views x[:, 1:2:end], x[:, 2:2:end]
    dx1, dx2 = @views dx[:, 1:2:end], dx[:, 2:2:end]

    z = x1 + im * x2
    dz = dx1 + im * dx2

    instantaneous_rotation(z, dz)
end

"""
    oscillator_rms(u)

Takes a matrix where the first axis is the time axis and the second axis is the oscillator index.
One oscillator is two columns representing displacement `y` and velocity `v`, respectively.

Returns the RMS value of the displacement `y` and velocity `v` for each oscillator as two separate vectors.
"""
function oscillator_rms(u::AbstractMatrix{Float64})::Tuple{Vector{Float64}, Vector{Float64}}
    # Extract displacement y and velocity v from the u matrix.
    # y values are all the odd columns and v values are all the even columns.
    y, v = @views u[:, 1:2:end], u[:, 2:2:end]

    # Calculate the RMS value for all columns of y and v.
    y_rms = vec(sqrt.(mean(y.^2, dims=1)))
    v_rms = vec(sqrt.(mean(v.^2, dims=1)))

    (y_rms, v_rms)
end

"""
    oscillator_winding_frequency(t, u)

Takes a time vector and a matrix where the first axis is the time axis and the second axis is the oscillator index.
One oscillator is two columns representing displacement `y` and velocity `v`, respectively.

A winding means the state revolves 2π around the origin in phase space.

Returns the winding frequency for each osicllator as a vector.
"""
function oscillator_winding_frequency(
    t::AbstractVector{Float64},
    u::AbstractMatrix{Float64}
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
    t::AbstractVector{Float64},
    u::AbstractMatrix{Float64}
)::Vector{Float64}
    du = diff(u, dims=1)
    dy, dv = @views du[:, 1:2:end], du[:, 2:2:end]
    θ = unwrap(atan.(dv, dy), dims=1)
    Δθ = θ[end, :] - θ[1, :]
    Δt = t[end-1] - t[1] # due to diff being one shorter, we consider the second-to-last element of t as well
    Δθ ./ Δt
end
