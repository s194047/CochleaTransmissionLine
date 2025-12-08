using LinearAlgebra
using DSP
using Plots


############################
# Parameters
############################

## FIXME: Defined (physical) constants.
@kwdef struct CochleaTransmissionLineParams
    # Number of discrete segments
    n::Int64

    # Length at cochlea apex
    x_apex_value::Float64

    # Membrane mass per unit area
    m::Float64

    # x-f map coefficient
    x_f_coeff::Float64

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

    # Fluid mass to CP mass ratio
    fluid_CP_β::Float64
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

    # Inverse coupling matrix
    inv_M::Matrix{Float64}
end

const f_R(x_positions, ctl_params::CochleaTransmissionLineParams) :: Vector{Float64} =
    let
        (; x_f_coeff, λ, κ) = ctl_params;

        # place-frequency (x-f) map
        x_f_coeff .* 10 .^ (-λ * x_positions) .- κ
    end

const sigmoid_scaling(x_norm::Float64, a::Float64, k::Float64) :: Float64 = a * 10^(k * x_norm)

const coupling_matrix(n::Int64, fluid_CP_β::Float64) :: Matrix{Float64} =
let
    K = -2.0 - fluid_CP_β;
    boundary_A = K - 1.0;
    boundary_B = 1.0;
    boundary_Y = 1.0;
    boundary_Z = -(1 + fluid_CP_β);    # + helicotrema_mass_ratio)

    M =
    Tridiagonal(
        [boundary_B; ones(n - 2)],
        [boundary_A; K * ones(n - 2); boundary_Z],
        [ones(n - 2); boundary_Y],
    )
end

const makeCochleaSolverInputParams(ctl_params::CochleaTransmissionLineParams) :: CochleaSolverInputParams =
    let
        (
            ;
            n,
            x_apex_value,
            m,
            δ_sat_a,
            δ_sat_k,
            δ_neg_a,
            δ_neg_k,
            σ_zweig_a,
            σ_zweig_k,
            fluid_CP_β
        ) = ctl_params;

        x_indices = 0:n;
        x_norm_positions = x_indices / n;
        x_positions = x_norm_positions * x_apex_value;
        f_values = f_R(x_positions, ctl_params);
        s_values = m * 4π^2 * f_values .^ 2;
        M = coupling_matrix(n, fluid_CP_β);

        CochleaSolverInputParams(
            ctl_params = ctl_params,
            x_norm_positions = x_norm_positions,
            τ_values = 1.742 ./ f_values,
            s_values = s_values,
            sqrt_m_times_s_values = sqrt.(m * s_values),
            δ_sat_values = sigmoid_scaling.(x_norm_positions, δ_sat_a, δ_sat_k),
            δ_neg_values = sigmoid_scaling.(x_norm_positions, δ_neg_a, δ_neg_k),
            σ_zweig_values = sigmoid_scaling.(x_norm_positions, σ_zweig_a, σ_zweig_k),
            inv_M = inv(M)
        )
    end

############################
# Functions
############################

# TODO: Implement a way to choose stimulus functions (e.g., sinusoidal, impulse, audio-file).
const stimulus(t::Float64) :: Float64 = 0.0

# Damping
const d_impl(
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
    sqrt_m_times_s_values,
) = let
        δ_sat = δ_sat_values[x_index+1];
        δ_neg = δ_neg_values[x_index+1];
        δ = δ_sat - δ_neg;
        sqrt_m_times_s = sqrt_m_times_s_values[x_index+1];

        (
            (1 - γ) * δ * ( 1 - 1 / (1 + exp((v_db - α) / μ_α)) ) +
            γ       * δ * ( 1 - 1 / (1 + exp((v_db - β) / μ_β)) ) +
            δ_neg
        ) * sqrt_m_times_s
end

# Feedback stiffness
const c_impl(
    ;
    x_index,
    v_db,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    σ_zweig_values,
) = let
        σ_zweig = σ_zweig_values[x_index+1];

        (1 - γ) * σ_zweig * ( 1 / (1 + exp((v_db - α) / μ_α)) ) +
        γ       * σ_zweig * ( 1 / (1 + exp((v_db - β) / μ_β)) )
end

############################
# instantiation
############################

const ctl_params = CochleaTransmissionLineParams(
    n = 1000,
    x_apex_value = 0.035,
    m = 0.375,
    x_f_coeff = 20_832,
    λ = 60,
    κ = 145.5,
    v_ref = 1e-6,
    δ_sat_a = 0.2,
    δ_sat_k = 0.52,
    δ_neg_a = -0.12,
    δ_neg_k = -0.17,
    σ_zweig_a = 0.1416,
    σ_zweig_k = -0.17,
    γ = 0.12,
    α = 40,
    μ_α = 6,
    β = -10,
    μ_β = 5,
    fluid_CP_β = 6.53e-3,
)

const cochlea_solver_input_params = makeCochleaSolverInputParams(ctl_params)

const d, c =
let
    (
        ;
        ctl_params,
        δ_sat_values,
        δ_neg_values,
        σ_zweig_values,
        sqrt_m_times_s_values,
    ) = cochlea_solver_input_params;
    (
        ;
        α,
        μ_α,
        β,
        μ_β,
        γ,
    ) = ctl_params;

    d = (x_index, v_db) -> d_impl(
        x_index = x_index,
        v_db = v_db,
        α = α,
        μ_α = μ_α,
        β = β,
        μ_β = μ_β,
        γ = γ,
        δ_sat_values = δ_sat_values,
        δ_neg_values = δ_neg_values,
        sqrt_m_times_s_values = sqrt_m_times_s_values,
    );
    c = (x_index, v_db) -> c_impl(
        x_index = x_index,
        v_db = v_db,
        α = α,
        μ_α = μ_α,
        β = β,
        μ_β = μ_β,
        γ = γ,
        σ_zweig_values = σ_zweig_values,
    );

    (d, c)
end

x_index = 0
v = 10 * ctl_params.v_ref
v_norm = v / ctl_params.v_ref
v_db = amp2db(v_norm)

@show d(x_index, v_db)
@show c(x_index, v_db)
@show d(x_index, v_db) / cochlea_solver_input_params.sqrt_m_times_s_values[x_index+1]

v_db_range = LinRange(-60, 90, 1000)
x_index = 0

d_values_unscaled =
    d.(x_index, v_db_range) ./
    cochlea_solver_input_params.sqrt_m_times_s_values[x_index+1]
c_values = c.(x_index, v_db_range)

x_lim_min = -60
x_lim_max = 90
x_tick_step = 20
y_lim_min = -0.2
y_lim_max = 0.5
y_tick_step = 0.1

xlims!(x_lim_min, x_lim_max)
xticks!(x_lim_min:x_tick_step:x_lim_max)
ylims!(y_lim_min, y_lim_max)
yticks!(y_lim_min:y_tick_step:y_lim_max)

plot!(v_db_range, d_values_unscaled, linewidth=2, color=:black, label="unscaled damping")
plot!(v_db_range, c_values, linewidth=2, color=:grey, label="feedback stiffness")

xlabel!("velocity / dB")
ylabel!("coefficient")

savefig("figures/test.png")
