using Parameters

#=
TODO:
- Move all constants to CochleaTransmissionLineParams.
- Unpack in “const d, c = ...” block
=#


############################
# Parameters
############################

## FIXME: Defined (physical) constants.
@kwdef struct CochleaTransmissionLineParams
    # Meta Parameters
    n::Int64                # Number of discrete segments
    x_apex_value::Float64   # Length at cochlea apex

    # Cochlear Partition (CP) Paramters
    m::Float64              # Membrane mass per unit area
    τ::Vector{Float64}      # Delay of feedback stiffness

    # Fluid Coupling Parameters
    β::Float64              # Fluid mass to CP mass ratio
    inv_M::Matrix{Float64}  # Inverse coupling matrix
    stimulus::Function      # Stapedial stimulus: t -> stimulus

    # Parameters for place-frequency map
    x_f_coeff = 20_832                            # x-f map coefficient
    λ = 60                                        # x-f map length constant
    κ = 145.5                                     # x-f map correction

    # Damping saturation
    #δ_sat = x_norm -> 0.2 * 10^(0.52 * x_norm);
    δ_sat_a = 0.2
    δ_sat_k = 0.52

    # Negative damping
    #δ_neg = x_norm -> -0.12 * 10^(-0.17 * x_norm);
    δ_neg_a = -0.12
    δ_neg_k = -0.17

    # Feedback stiffness amplitude
    #σ_zweig = x_norm -> 0.1416 * 10^(-0.17 * x_norm);
    σ_zweig_a = 0.1416
    σ_zweig_k = -0.17
end

## FIXME: Calculated / derived parameters
@kwdef struct CochleaSolverInputParams
    ctl_params::CochleaTransmissionLineParams

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
end

const f_R(x_positions, ctl_params::CochleaTransmissionLineParams) :: Vector{Float64} =
    let
        (; x_f_coeff, λ, κ) = ctl_params;

        # place-frequency (x-f) map
        x_f_coeff .* 10 .^ (-λ * x_positions) .- κ
    end

const sigmoid_scaling(x_norm, n, x_apex, a, k) = a * 10^(k * x_norm)

const makeCochleaSolverInputParams(ctl_params::CochleaTransmissionLineParams) :: CochleaSolverInputParams =
    let
        (; n, x_apex, m, δ_sat_a, δ_sat_k, δ_neg_a, δ_neg_k, σ_zweig_a, σ_zweig_k) = ctl_params;
        x_indices = 0:n;
        x_norm_positions = x_indices / n;
        x_positions = x_norm_positions * x_apex;
        f_values = f_R(x_positions, ctl_params);
        CochleaSolverInputParams(
            ctl_params = ctl_params,
            x_norm_positions = x_norm_positions,
            τ_values = 1.742 ./ f_values,
            s_values = m * 4π^2 * f_values .^ 2,
            sqrt_m_times_s_values = sqrt.(m * s_values),
            sigmoid_scaling.(x_norm_positions, δ_sat_a, δ_sat_k),
            sigmoid_scaling.(x_norm_positions, δ_neg_a, δ_neg_k),
            sigmoid_scaling.(x_norm_positions, σ_zweig_a, σ_zweig_k),
        )
    end

#const default_parameters =

# Membrane mass per unit area
const m = () -> 0.375

# Velocity level in dB
v_ref = 1e-6;

# Amplitude of plateau
γ = 0.12;

# Middle turning point velocity
α = 40;

# Slope at middle turning point
μ_α = 6;

# Lower turning point velocity
β = -10;

# Slope at lower turning point
μ_β = 5;

sigmoid_scaling(x_norm, a, k) = a * 10^(k * x_norm)

# Damping saturation
#δ_sat = x_norm -> 0.2 * 10^(0.52 * x_norm);
δ_sat_a = 0.2
δ_sat_k = 0.52

# Negative damping
#δ_neg = x_norm -> -0.12 * 10^(-0.17 * x_norm);
δ_neg_a = -0.12
δ_neg_k = -0.17

# Feedback stiffness amplitude
#σ_zweig = x_norm -> 0.1416 * 10^(-0.17 * x_norm);
σ_zweig_a = 0.1416
σ_zweig_k = -0.17

############################
# Functions
############################

# Decibel of v relative to v_ref
#const Λ(v, v_ref) = v -> 20 * log10(abs(v) / v_ref)
const Λ(v_norm) = v -> 20 * log10(abs(v_norm))

# Damping
const d_impl(
    x_index,
    v_norm,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    δ_sat_values,
    δ_neg_values,
    sqrt_m_times_s_values,
) = let
        δ_sat = δ_sat_values[x_index-1];
        δ_neg = δ_neg_values[x_index-1];
        δ = δ_sat - δ_neg;
        sqrt_m_times_s = sqrt_m_times_s_values[x_index-1];
        v_db = Λ(v_norm);

        (
            (1 - γ) * δ * ( 1 - 1 / (1 + exp((v_db - α) / μ_α)) ) +
            γ       * δ * ( 1 - 1 / (1 + exp((v_db - β) / μ_β)) ) +
            δ_neg
        ) * sqrt_m_times_s
end

# Feedback stiffness
const c_impl(
    x_index,
    v_norm,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    σ_zweig_values,
) = let
        σ_zweig = σ_zweig_values[x_index-1];
        v_db = Λ(v_norm);

        (1 - γ) * σ_zweig * ( 1 / (1 + exp((v_db - α) / μ_α)) ) +
        γ       * σ_zweig * ( 1 / (1 + exp((v_db - β) / μ_β)) )
end

const d, c =
let
    d = (x_norm, v_norm) -> d_impl(x_norm, v_norm, α, μ_α, β, μ_β, γ, δ_sat_values, δ_neg_values, sqrt_m_times_s_values);
    c = (x_norm, v_norm) -> c_impl(x_norm, v_norm, α, μ_α, β, μ_β, γ, σ_zweig_values);

    (d, c)
end


d(0.0, 0.0)
c(0.0, 0.0)
