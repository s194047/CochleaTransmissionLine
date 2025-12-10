using CochleaTransmissionLine

using DelayDiffEq

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

const tspan = (0.0, 0.001)

problem = DDEProblem(
    cochlea_transmission_line!,
    u0,
    u0_history,
    tspan,
    solver_params,
)

algorithm = MethodOfSteps(Tsit5())

simulation_time = @elapsed solution = solve(problem, algorithm)

# TODO: Figure out how to save the solution. Use the method sketched in
#       scratch/serialize.jl
