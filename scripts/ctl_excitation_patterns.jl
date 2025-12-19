using CochleaTransmissionLine

using DelayDiffEq
using JLD2
using Plots

const ctl_constants = default_ctl_constants
const solver_params = makeCochleaSolverInputParams(
    ctl_constants
)

const u0 = repeat(default_u0_value, outer=ctl_constants.n+1)
const u0_history(
    ::CochleaSolverInputParams,
    ::Float64,
    ;
    idxs=nothing,
) =
    if idxs == nothing
        u0
    else
        u0[idxs]
    end

const tspan = (0.0, 0.200)

#const stimulus(t::Float64) :: Float64 = 1 * sin(2π * 100 * t)

problem = DDEProblem(
    cochlea_transmission_line!,
    u0,
    u0_history,
    tspan,
    solver_params,
)

algorithm = MethodOfSteps(Tsit5())

solution = solve(problem, algorithm, abstol=1e-10)

sampling_freq = 1e5
t_values = tspan[1] : 1/sampling_freq : tspan[2]
t_end_values = tspan[2] - 0.100 : 1/sampling_freq : tspan[2]

_, u = get_solution_samples(solution, t_values)
_, u_end = get_solution_samples(solution, t_end_values)

#@save "data/ctl_excitation_patterns.jld2" t_values u

## Calculate the max amplitude of each CP
y = @view u[:, 1:2:end]
v = @view u[:, 2:2:end]
y_end = @view u_end[:, 1:2:end]
v_end = @view u_end[:, 2:2:end]

max_v_amplitudes = reshape(maximum(abs.(v_end), dims=1), ctl_constants.n + 1)

plot(0:ctl_constants.n,20 * log10.(max_v_amplitudes ./ 10^(-6)))

let idx_values = 1:3;
    heatmap(t_values, idx_values, v[:, idx_values]')
end

plot(t_values, y[:, 1:3], xlims=(0.100, 0.110))
plot(t_values, y[:, end-10:end], xlims=(0.000, 0.200))
