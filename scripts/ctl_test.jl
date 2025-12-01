using CochleaTransmissionLine

using LinearAlgebra
using DelayDiffEq
using Plots
using Random
const rng = Xoshiro(0)                              # Use a seeded rng
                                                    # for reproducibility

# TODO: We should implement n + 1 sections with 0-indexing
const n = 1000                                      # Number of discrete segments

const x_apex = 35e-3                                # Length at apex

const x = LinRange(0.0, x_apex, n)                  # Longitudinal coordinate

# Intrinsic paramters
# ===================

const A = 20_832                                    # x-f map coefficient
const λ = 60                                        # x-f map length constant
const κ = 145.5                                     # x-f map correction

const f_R(x) = A .* 10 .^ (-λ * x) .- κ                # place-frequency (x-f) map
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

const param = CochleaTransmissionLineParam(
    n=n,
    x=x,
    m=m,
    d=d,
    s=s,
    c=c,
    τ=τ,
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

fs = 1e5 # Sampling rate (Hz)

t, u = get_solution_samples(solution, fs)
y, v = @views u[:, 1:2:end], u[:, 2:2:end]

#plot(t, y, leg=false)

begin
    osc_idx_range = 10:10
    t_min = 0.050
    t_max = 0.100
    t_idx_range = Int(floor(t_min * fs)):Int(floor(t_max * fs))
    heatmap(osc_idx_range, t[t_idx_range], v[t_idx_range, osc_idx_range])
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
