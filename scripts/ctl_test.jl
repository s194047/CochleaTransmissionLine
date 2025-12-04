using CochleaTransmissionLine

using LinearAlgebra
using DelayDiffEq
using Plots
using Random
using Statistics

const rng = Xoshiro(0)                              # Use a seeded rng
                                                    # for reproducibility

# TODO: We should implement n + 1 sections with 0-indexing
const n = 1000                                      # Number of discrete segments

const x_apex = 35e-3                                # Length at apex

const x = LinRange(0.0, x_apex, n)                  # Longitudinal coordinate

# Intrinsic paramters
# ===================

const x_f_coeff = 20_832                            # x-f map coefficient
const λ = 60                                        # x-f map length constant
const κ = 145.5                                     # x-f map correction

const f_R(x) = x_f_coeff .* 10 .^ (-λ * x) .- κ     # place-frequency (x-f) map
const τ = 1.742 ./ f_R.(x)                          # Delay of feedback stiffness

const v_ref = 1e-6                                  # Reference velocity
const Λ(v) = 20 * log10(abs(v) / v_ref)             # Velocity level in dB

const sigm_γ = 0.12                                 # Amplitude of plateau
const sigm_α = 40                                   # Middle turning point velocity
const sigm_μ_α = 6                                  # Slope at middle turning point
const sigm_β = -10                                  # Lower turning point velocity
const sigm_μ_β = 5                                  # Slope at lower turning point

const δ_sat(x) = 0.2 * 10^(0.52 * x / x_apex)       # Damping saturation
const δ_neg(x) = -0.12 * 10^(-0.17 * x / x_apex)    # Negative damping
const σ_zweig(x) = 0.1416 * 10^(-0.17 * x / x_apex) # Feedback stiffness amplitude

const m = 0.375                                     # Membrane mass per unit area

# TODO: Should we remove all x dependency and instead vectorize it?
const s(x) = m * 4π^2 * f_R(x) .^ 2                 # Membrane stiffness

const d(x, v) =                                     # Membrane damping
    (
        (1 - sigm_γ) * (δ_sat(x) - δ_neg(x)) *
        (
            1 - 1 /
            (1 + exp((Λ(v) - sigm_α) / sigm_μ_α))
        ) +
        sigm_γ * (δ_sat(x) - δ_neg(x)) *
        (
            1 - 1 /
            (1 + exp((Λ(v) - sigm_β) / sigm_μ_β))
        ) +
        δ_neg(x)
    ) *
    sqrt(m * s(x))

const c(x, v) =                                     # Feedback stiffness term
    (1 - sigm_γ) * σ_zweig(x) *
    (
        1 /
        (1 + exp.((Λ.(v) .- sigm_α) / sigm_μ_α))
    ) +
    sigm_γ * σ_zweig(x) *
    (
        1 /
        (1 + exp((Λ.(v) - sigm_β) / sigm_μ_β))
    )

const ϵ = 0.01                                      # Roughness scaling coefficient
const N_s_rough = randn(rng, n)                     # Normal distribution samples with
                                                    # μ = 0, σ = 1

const s_rough = s.(x) .* (1 .+ ϵ * N_s_rough)       # Membrane stiffness with roughness

# Coupling Parameters
# ===================

const β = 0.1               # Fluid mass to CP mass ratio
const K = -2.0 - β
const bound_A = K - 1.0
const bound_B = 1.0
const bound_Y = 1.0
const bound_Z = -(1 + β)    # + helicotrema_mass_ratio)
const M =                   # Coupling matrix
Tridiagonal(
    [bound_B; ones(n - 2)],
    [bound_A; K * ones(n - 2); bound_Z],
    [ones(n - 2); bound_Y],
)

const inv_M = inv(M)        # Inverse coupling matrix
const stimulus(t) = 0.0     # Stapedial stimulus

# Wrap all parameters into an object for the solver
const param = CochleaTransmissionLineParam(
    n=n,
    x=x,
    m=m,
    d=d,
    s=s,
    c=c,
    τ=τ,
    β=β,
    inv_M=inv_M,
    stimulus=stimulus,
)

# Construct and solve problem
# ===========================

const u0 = repeat([1e-9, 0.0], outer=n)
function u_history(
    ::CochleaTransmissionLineParam,
    ::Float64,
    ;
    idxs=nothing,
)
    if idxs == nothing
        u0
    else
        u0[idxs]
    end
end
const tspan = (0.0, 0.100)

problem = DDEProblem(
    cochlea_transmission_line!,
    u0,
    u_history,
    tspan,
    param,
)

algorithm = MethodOfSteps(Tsit5())

simulation_time = @elapsed solution = solve(problem, algorithm)

@save data_filename solution

# Analyze the data
# ================

fs = 1e6 # Sampling rate (Hz)

t, u = get_solution_samples(solution, fs)
_, du = get_solution_samples(solution, fs, Val{1})
y, v = @views u[:, 1:2:end], u[:, 2:2:end]
dy, dv = @views du[:, 1:2:end], du[:, 2:2:end]

# TODO: Consider putting the scaling into a function in data analysis
ω_R = 2π * stack([f_R.(x)], dims=1)
u_scaled = copy(u)
du_scaled = copy(du)
v_scaled = @view u_scaled[:, 2:2:end]
dv_scaled = @view du_scaled[:, 2:2:end]
v_scaled .= v ./ ω_R
dv_scaled .= dv ./ ω_R

ρ_inst = instantaneous_rotation(u_scaled, du_scaled)

begin
    osc_idx_range = 1:500
    t_min = 0.09500
    t_max = 0.10000
    t_idx_range = Int(floor(t_min * fs)) + 1:Int(floor(t_max * fs)) + 1
    heatmap(osc_idx_range, t[t_idx_range], v[t_idx_range, osc_idx_range])
end
begin
    osc_idx_range = 500:1000
    t_min = 0.09000
    t_max = 0.10000
    t_idx_range = Int(floor(t_min * fs)) + 1:Int(floor(t_max * fs)) + 1
    heatmap(osc_idx_range, t[t_idx_range], v[t_idx_range, osc_idx_range])
end

begin
    osc_idx_range = 250:255
    t_min = 0.01000
    t_max = 0.01100
    t_idx_range = Int(floor(t_min * fs)):Int(floor(t_max * fs))
    plot(t[t_idx_range], v[t_idx_range, osc_idx_range], leg=false)
end

begin
    osc_idx_range = 1:1000
    t_min = 0.01000
    t_max = 0.01100
    t_idx_range = Int(floor(t_min * fs)):Int(floor(t_max * fs))
    ρ_mean = vec(mean(ρ_inst[t_idx_range, osc_idx_range], dims=1))
    scatter(osc_idx_range, ρ_mean, leg=false)
    ylims!(0, 30_000)
end

# begin
    #     x = 0.000
#     v = logrange(1e-9, 1e-2, 100)
#     plot()
#     plot!(Λ.(v), d.(x, v) / sqrt(m * s(x)))
#     plot!(Λ.(v), c.(x, v))
#     ylims!(-.2, .5)
#     xlims!(-60, 80)
# end
