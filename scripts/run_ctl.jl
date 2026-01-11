using CochleaTransmissionLine

using YAML
using DelayDiffEq

function zero_stimulus(t::Float64)::Float64
    0.0
end

const stimulus_functions = Dict{String, Function}(
    "zero" => zero_stimulus
)
function load_stimulus(stimulus_type::String)
    stimulus_functions[stimulus_type]
end

function load_paramters(config_filename::String)
    cfg = YAML.load_file(config_filename)

    ctl_constants = CochleaTransmissionLineConstants(
        ;
        (Pair(Symbol(k), v) for (k, v) in cfg["transmission_line"])...
    )
    u0_value = cfg["u0_value"]

    stimulus = load_stimulus(cfg["stimulus"])

    (ctl_constants, u0_value, stimulus)
end

function main()

    # Check that a file name was provided
    if length(ARGS) < 1
        println("Pass parameter TOML file as first argument.")
        exit(1)
    end

    config_filename = ARGS[1]

    ctl_constants, u0_value, stimulus = load_paramters(config_filename)
    solver_params = makeCochleaSolverInputParams(
        ctl_constants,
        stimulus,
    )

    u0 = repeat(u0_value, outer=ctl_constants.n+1)
    u0_history(
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

    tspan = (0.0, 1.000)

    problem = DDEProblem(
        cochlea_transmission_line!,
        u0,
        u0_history,
        tspan,
        solver_params,
    )

    algorithm = MethodOfSteps(Tsit5())

    simulation_time = @elapsed solution = solve(problem, algorithm)
    @show simulation_time

    # TODO: Figure out how to save the solution. Use the method sketched in
    #       scratch/serialize.jl
end

# Only run if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
