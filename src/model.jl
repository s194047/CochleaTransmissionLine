using DSP
using LinearAlgebra

#=====================
Define Parameter Types
=====================#

# TODO: streamline the "calculate" functions to either take and return a vector or
#       single values. If they take single values, they should be broadcast when called.
@kwdef struct CochleaTransmissionLineConstants
    # Number of discrete segments
    n::Int64

    # Length at cochlea apex
    x_apex_value::Float64

    # Membrane mass per unit area
    m::Float64

    # x-f map coefficient
    A::Float64

    # x-f map length constant
    λ::Float64

    # x-f map correction
    κ::Float64

    # Velocity level in dB
    v_ref::Float64

    # Damping saturation
    #δ_sat::Float64
    δ_sat_a::Float64
    δ_sat_k::Float64

    # Negative damping
    #δ_neg::Float64
    δ_neg_a::Float64
    δ_neg_k::Float64

    # Feedback stiffness amplitude
    #σ_zweig::Float64
    σ_zweig_a::Float64
    σ_zweig_k::Float64

    # Nonlinearity scaling taper coefficient
    nonlin_scaling_taper::Float64

    # Amplitude of plateau
    γ::Float64

    # Middle turning point velocity
    α::Float64

    # Slope at middle turning point
    μ_α::Float64

    # Lower turning point velocity
    β::Float64

    # Slope at lower turning point
    μ_β::Float64

    # TODO: Consider giving ρ, m and h rather than κ and calculate κ = κ = 2ρ / (m * h).
    #       Δx should be calculated as: Δx = x_apex_value / n
    # Fluid mass to Cochlear Partion mass ratio
    fluid_CP_κ::Float64
end

@kwdef struct CochleaTransmissionLineParams
    # Positions along the Scala of Cochlea
    x_norm_positions::Vector{Float64}

    # Delay of feedback stiffness
    τ_values::Vector{Float64}

    # Membrane stiffness
    s_values::Vector{Float64}
    sqrt_m_times_s_values::Vector{Float64}

    # Sigmoid scaling values
    δ_sat_values::Vector{Float64}
    δ_neg_values::Vector{Float64}
    σ_zweig_values::Vector{Float64}

    # Nonlinearity scaling values
    nonlin_scaling_values::Vector{Float64}

    # Scaled Fluid mass to Cochlear Partion mass ratio
    fluid_CP_β::Float64

    # Inverse coupling matrix
    inv_M::Matrix{Float64}
end

@kwdef struct CochleaTransmissionLineFunctions
    # Damping
    d::Function

    # Feedback stiffness
    c::Function
end

@kwdef struct CochleaModelParams
    ctl_constants::CochleaTransmissionLineConstants
    ctl_params::CochleaTransmissionLineParams
    ctl_functions::CochleaTransmissionLineFunctions
    stimulus::Function
end

#====================================
Differential Equation for the Problem
====================================#

# FIXME: The first element should actually be considered the middle ear.
#        The distance between element 0 and 1 is Δx₀ which is different from Δx.
#        These things should somehow be taken into account to have the correct
#        boundary conditions and stimulus.

function cochlea_transmission_line!(
    du::Vector{Float64},
    u::Vector{Float64},
    u_history, # History function
    solver_params::CochleaModelParams,
    t::Float64,
)
    # Define views for state and derivative of the
    # transverse displacement y and transverse velocity v
    dy, dv = @views du[1:2:end], du[2:2:end]
    y, v = @views u[1:2:end], u[2:2:end]

    # Extract parameters
    (; ctl_constants, ctl_params, ctl_functions, stimulus) = solver_params
    (; n, m, v_ref) = ctl_constants
    (; τ_values, s_values, fluid_CP_β, inv_M) = ctl_params
    (; d, c) = ctl_functions

    # Wrap history function and evaluate delayed values of y
    history_broadcast_wrapper(p, t, idxs) = u_history(p, t, idxs=idxs)
    y_delayed = history_broadcast_wrapper.(
        Ref(solver_params),
        t .- τ_values,
        1:2:2n+1,
    )

    # Calculate decibel value of v
    v_db = amp2db.(abs.(v ./ v_ref))

    # Calculate the force from the intrinsic dynamics of the CP
    g = d.(0:n, v_db) .* v +
        s_values .* (y + c.(0:n, v_db) .* y_delayed)

    # Build the stimulus vector
    b = [stimulus(t); zeros(n - 1); 0.0] # should be apex]

    dy .= v
    dv .= 1 / m * (
        -g +
        inv_M * (
            -fluid_CP_β .* g +
            b
        )
    )

    nothing
end

# TODO: Consider if it's more efficient to implement d and c to work on a vector
# Damping
const damping_impl(
    ;
    x_index,
    v_db,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    δ_sat_values,
    δ_neg_values,
    nonlin_scaling_values,
    sqrt_m_times_s_values,
) = let
        δ_sat = δ_sat_values[x_index+1];
        δ_neg = δ_neg_values[x_index+1];
        nonlin_scaling = nonlin_scaling_values[x_index+1]
        δ_neg_scaled = δ_neg * nonlin_scaling + δ_sat * (1 - nonlin_scaling)
        δ = δ_sat - δ_neg_scaled;
        sqrt_m_times_s = sqrt_m_times_s_values[x_index+1];

        (
            (1 - γ) * δ * ( 1 - 1 / (1 + exp((v_db - α) / μ_α)) ) +
            γ       * δ * ( 1 - 1 / (1 + exp((v_db - β) / μ_β)) ) +
            δ_neg_scaled
        ) * sqrt_m_times_s
end

# Feedback stiffness
const feedback_stiffness_impl(
    ;
    x_index,
    v_db,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    σ_zweig_values,
    nonlin_scaling_values,
) = let
        σ_zweig = σ_zweig_values[x_index+1];
        nonlin_scaling = nonlin_scaling_values[x_index+1]

        (
            (1 - γ) * σ_zweig * ( 1 / (1 + exp((v_db - α) / μ_α)) ) +
            γ       * σ_zweig * ( 1 / (1 + exp((v_db - β) / μ_β)) )
        ) * nonlin_scaling
end

#=======================================
Define Functions for Building Parameters
=======================================#

"""
    Calculate Frequencies

Calculates the frequencies of the Greenwood frequency map for each position.
The frequency map is defined by the parameters `A` (x-f map coefficient), `λ` (x-f map length constant), and `κ` (x-f map correction).

The frequencies are is returned as a vector of same length as `x_positions`.
"""
const calculate_frequencies(
    ;
    x_positions::Union{StepRangeLen{Float64}, Vector{Float64}},
    A::Float64,
    λ::Float64,
    κ::Float64,
) :: Vector{Float64} =
let
    # place-frequency (x-f) map
    A .* 10 .^ (-λ * x_positions) .- κ
end

"""
    Calculate Sigmoid Scaling

Calculates a scaling parameter for a sigmoid function which varies over the length `x` of the cochlea transmission line model.
"""
const calculate_sigmoid_scaling(x_norm::Float64, a::Float64, k::Float64) :: Float64 = a * 10^(k * x_norm)

"""
    Calculate Nonlinearity Scaling

This vector defines the scaling of the nonlinearity parameters d and c in the model.
The CP behaviour should approach a linear model towards the base and apex. This scaling makes sure that δ approaches δ_sat and σ_zweig approaches 0 at both ends of the transmission line.

This implementation is a modified implementation of the Tukey window:
https://docs.juliadsp.org/stable/windows/#DSP.Windows.tukey
"""
function calculate_nonlin_scaling(n::Int64, α::Float64) :: Vector{Float64}
    # check that α is reasonable
    !(0 <= α <= 1) && throw(DomainError(α, "α must be in the range [0, 1]."))

    # if α is less than machine precision, call it zero and return the
    # rectangular window for this length.  if we don't short circuit this
    # here, it will blow up below.
    abs(α) <= eps() && return DSP.Windows.rect(n)

    DSP.Windows.makewindow(n, 0, false) do x
        if x <= -(1-α)/2
            sinpi((0.5 + x) / α)
        elseif x <= (1-α)/2
            1.0
        else
            sinpi((0.5 - x) / α)
        end
    end
end

# TODO: Z should be calculated as Z = -(1 + fluid_CP_β + helicotrema_mass_ratio)
"""
    Calculate Inverse Coupling Matrix

The transmission line is defined by a second-order spatial derivative (Laplacian operator ∇²), which is discretized into a spatial difference equation with a Laplacian matrix. The full matrix `M` in the difference equation is the Laplacian matrix subtracted with the fluid to CP mass  `β` along the diagonal.

When solving the time-differential equation, the inverse of the matrix `M` needs to be applied to the state and stimulus. Using the inverse of `M` is equivalent to solving the spatial equation through gaussian elimination. The coupling parameters are time independent so the inverse of `M` should only be calculated once.
"""
const calculate_inverse_coupling_matrix(n::Int64, fluid_CP_β::Float64) :: Matrix{Float64} =
let
    K = -2.0 - fluid_CP_β;
    A = K - 1.0;
    B = 1.0;
    Y = 1.0;
    Z = -(1 + fluid_CP_β);    # + helicotrema_mass_ratio)
    M =
    Tridiagonal(
        [B; ones(n - 1)],
        [A; K * ones(n - 1); Z],
        [ones(n - 1); Y],
    );
    inv(M)
end

const makeCochleaTransmissionLineParams(ctl_constants::CochleaTransmissionLineConstants) :: CochleaTransmissionLineParams =
let
    (
        ;
        n,
        x_apex_value,
        m,
        A, λ, κ,
        δ_sat_a, δ_sat_k,
        δ_neg_a, δ_neg_k,
        σ_zweig_a, σ_zweig_k,
        nonlin_scaling_taper,
        fluid_CP_κ,
    ) = ctl_constants;

    x_indices = 0:n;
    x_norm_positions = x_indices / n;
    x_positions = x_norm_positions * x_apex_value;
    f_values = calculate_frequencies(x_positions = x_positions, A = A, λ = λ, κ = κ);
    s_values = m * 4π^2 * f_values .^ 2;
    Δx = x_apex_value / n
    fluid_CP_β = Δx^2 * fluid_CP_κ
    CochleaTransmissionLineParams(
        x_norm_positions = x_norm_positions,
        τ_values = 1.742 ./ f_values,
        s_values = s_values,
        sqrt_m_times_s_values = sqrt.(m * s_values),
        δ_sat_values = calculate_sigmoid_scaling.(x_norm_positions, δ_sat_a, δ_sat_k),
        δ_neg_values = calculate_sigmoid_scaling.(x_norm_positions, δ_neg_a, δ_neg_k),
        σ_zweig_values = calculate_sigmoid_scaling.(x_norm_positions, σ_zweig_a, σ_zweig_k),
        nonlin_scaling_values = calculate_nonlin_scaling(length(x_indices), nonlin_scaling_taper),
        fluid_CP_β = fluid_CP_β,
        inv_M = calculate_inverse_coupling_matrix(n, fluid_CP_β),
    )
end

const makeCochleaTransmissionLineFunctions(
ctl_constants::CochleaTransmissionLineConstants,
ctl_params::CochleaTransmissionLineParams,
) :: CochleaTransmissionLineFunctions =
let
    (
        ;
        α,
        μ_α,
        β,
        μ_β,
        γ,
    ) = ctl_constants;
    (
        ;
        δ_sat_values,
        δ_neg_values,
        σ_zweig_values,
        nonlin_scaling_values,
        sqrt_m_times_s_values,
    ) = ctl_params;

    d = (x_index, v_db) -> damping_impl(
        x_index = x_index,
        v_db = v_db,
        α = α,
        μ_α = μ_α,
        β = β,
        μ_β = μ_β,
        γ = γ,
        δ_sat_values = δ_sat_values,
        δ_neg_values = δ_neg_values,
        nonlin_scaling_values = nonlin_scaling_values,
        sqrt_m_times_s_values = sqrt_m_times_s_values,
    );
    c = (x_index, v_db) -> feedback_stiffness_impl(
        x_index = x_index,
        v_db = v_db,
        α = α,
        μ_α = μ_α,
        β = β,
        μ_β = μ_β,
        γ = γ,
        σ_zweig_values = σ_zweig_values,
        nonlin_scaling_values = nonlin_scaling_values,
    );

    CochleaTransmissionLineFunctions(d = d, c = c)
end

const makeCochleaModelParams(
    ctl_constants::CochleaTransmissionLineConstants,
    stimulus::Function,
) :: CochleaModelParams =
let
    ctl_params = makeCochleaTransmissionLineParams(ctl_constants);
    CochleaModelParams(
        ctl_constants = ctl_constants,
        ctl_params = ctl_params,
        ctl_functions = makeCochleaTransmissionLineFunctions(ctl_constants, ctl_params),
        stimulus = stimulus,
    )
end
