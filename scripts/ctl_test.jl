using CochleaTransmissionLine

using LinearAlgebra
using OrdinaryDiffEq
using Plots
using Random

rng = Xoshiro(0)

n = 101                             # Number of discrete segments

x_apex = 35e-3                      # Length at apex

x = LinRange(0.0, x_apex, n)        # Longitudinal coordinate
x_norm = LinRange(0.0, 1.0, n)      # Normalized length

# Intrinsic paramters
# ===================

A = 20_832                          # x-f map coefficient
λ = 60                              # x-f map length constant
κ = 145.5                           # x-f map correction

f_R = A * 10 .^ (-λ * x) .- κ       # place-frequency (x-f) map
τ = 1.742 ./ f_R                    # Delay of feedback stiffness

y_ref = 1e-6                        # Reference velocity
Λ(y) = 20 * log10(abs(y) / y_ref)   # Velocity level in dB

γ = 0.12                            # Amplitude of plateau
α = 40                              # Middle turning point velocity
μ_α = 6                             # Slope at middle turning point
β = -10                             # Lower turning point velocity
μ_β = 5                             # Slope at lower turning point

δ_sat = 0.2 * 10 .^ (0.52x_norm)        # Damping saturation
δ_neg = -0.12 * 10 .^ (-0.17x_norm)     # Negative damping
σ_zweig = 0.1416 * 10 .^ (-0.17x_norm)  # Feedback stiffness amplitude

m = 0.375                           # Membrane mass per unit area
s = 2π * m^2 * f_R .^ 2             # Membrane stiffness

d(y) = (1 - γ) * (δ_sat - δ_neg) / (1 .+ exp.((Λ.(y) .- α) / μ_α)) +
       γ * (δ_sat - δ_neg) / (1 .+ exp.((Λ.(y) .- α) / μ_α))            # Membrane damping

c(y) = (1 - γ) * σ_zweig / (1 .+ exp.((Λ.(y) .- α) / μ_α)) +
       γ * σ_zweig / (1 .+ exp.((Λ.(y) .- α) / μ_α))                    # Feedback stiffness term

ϵ = 0.01                            # Roughness scaling coefficient
N = randn(rng, n)                   # Normal distribution samples with μ = 0, σ = 1

s_rough = s .* (1 .+ ϵ * N)         # Membrane stiffness with perturbation

# Coupling paramters
# ==================

# β(x) = 0.1
# mann = 0.1;
# manh = 0.01;
# dah = 0.1;
# A = -3 - β(x[n])
# B = 1
# Y = 1
# Z = -1 - mann - manh
# M = Tridiagonal(ones(n - 1), -2 .- β.(x), ones(n - 1))
# M[1, 1:2] = [A B]
# M[end, end-1:end] = [Y Z]
# inv_M = inv(M)

#drive(t) = sin(2 * π * 0.1 * t) #t < 0.100 ? 1.0 : 0.0
#apex = -manh * dah

param = CochleaTransmissionLineParam(
    n=n,
    x=x,
    m=m,
    d=d,
    s=s,
    #inv_M=inv_M,
    #β=β,
    #drive=drive,
    #apex=apex,
)

u0 = repeat([0.0, 0.0], outer=n)
tspan = (0.0, 100.0)

problem = ODEProblem(
    cochlea_transmission_line!,
    u0,
    tspan,
    param,
)

algorithm = Tsit5()

solution = solve(problem, algorithm)


fs = 1e3

t, u = get_solution_samples(solution, fs)
y, v = @views u[:, 1:2:end], u[:, 2:2:end]

#plot(t, y, leg=false)

heatmap(1:n, t, v)
