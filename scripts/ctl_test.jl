using CochleaTransmissionLine

using LinearAlgebra
using OrdinaryDiffEq
using Plots
using Random

rng = Xoshiro(0)

n = 10                             # Number of discrete segments

x_apex = 35e-3                      # Length at apex

x = LinRange(0.0, x_apex, n)        # Longitudinal coordinate

# Intrinsic paramters
# ===================

A = 20_832                          # x-f map coefficient
λ = 60                              # x-f map length constant
κ = 145.5                           # x-f map correction

f_R(x) = A * 10 ^ (-λ * x) - κ    # place-frequency (x-f) map
τ(x) = 1.742 ./ f_R(x)              # Delay of feedback stiffness

v_ref = 1e-6                        # Reference velocity
Λ(v) = 20 * log10(abs(v) / v_ref)   # Velocity level in dB

γ = 0.12                            # Amplitude of plateau
α = 40                              # Middle turning point velocity
μ_α = 6                             # Slope at middle turning point
β = -10                             # Lower turning point velocity
μ_β = 5                             # Slope at lower turning point

δ_sat(x) = 0.2 * 10^(0.52 * x / x_apex)          # Damping saturation
δ_neg(x) = -0.12 * 10^(-0.17 * x / x_apex)       # Negative damping
σ_zweig(x) = 0.1416 * 10^(-0.17 * x / x_apex)    # Feedback stiffness amplitude

m = 0.375                           # Membrane mass per unit area
s(x) = m * 4π^2 * f_R(x)^2             # Membrane stiffness

# Membrane damping
d(x, v) =
    ((1 - γ) * (δ_sat(x) - δ_neg(x)) * (1 - 1 / (1 + exp((Λ(v) - α) / μ_α))) +
     γ * (δ_sat(x) - δ_neg(x)) * (1 - 1 / (1 + exp((Λ(v) - β) / μ_β))) +
     δ_neg(x)) * sqrt(m * s(x))

# Feedback stiffness term
c(x, v) =
    (1 - γ) * σ_zweig(x) * (1 / (1 + exp.((Λ.(v) .- α) / μ_α))) +
    γ * σ_zweig(x) * (1 / (1 + exp((Λ.(v) - β) / μ_β)))

ϵ = 0.01                            # Roughness scaling coefficient
N = randn(rng, n)                   # Normal distribution samples with μ = 0, σ = 1

s_rough = s.(x) .* (1 .+ ϵ * N)         # Membrane stiffness with perturbation

param = CochleaTransmissionLineParam(
    n=n,
    x=x,
    m=m,
    d=d,
    s=s,
)

u0 = repeat([1e-9, 0.0], outer=n)
tspan = (0.0, 10.0)

problem = ODEProblem(
    cochlea_transmission_line!,
    u0,
    tspan,
    param,
)

algorithm = Tsit5()

solution = solve(problem, algorithm)

fs = 1e5 # Sampling rate (Hz)

t, u = get_solution_samples(solution, fs)
y, v = @views u[:, 1:2:end], u[:, 2:2:end]

#plot(t, y, leg=false)

heatmap(1:n, t, v)

# begin
#     x = 0.000
#     v = logrange(1e-9, 1e-2, 100)
#     plot()
#     plot!(Λ.(v), d.(x, v) / sqrt(m * s(x)))
#     plot!(Λ.(v), c.(x, v))
#     ylims!(-.2, .5)
#     xlims!(-60, 80)
# end
