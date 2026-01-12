using CochleaTransmissionLine

using YAML
using DelayDiffEq

# TODO: Implement sine and audio options for stimulus. These require extra parameters.
#       YAML could be:
#         stimulus:
#             type: "zero"
#         stimulus:
#             type: "sine"
#             frequency: 15000
#             phase: ??
#         stimulus:
#             type: "audio"
#             filename: "tinnitus.wav"
function zero_stimulus(t::Float64)::Float64
    0.0
end

const stimulus_functions = Dict{String, Function}(
    "zero" => zero_stimulus
)
function load_stimulus(stimulus_type::String)
    stimulus_functions[stimulus_type]
end

@kwdef struct SolverParams
    u0_value::Vector{Float64}
    tspan::Vector{Float64}
    saveat::Union{Float64, Vector{Float64}}
end

function load_paramters(config_filename::String)
    cfg = YAML.load_file(config_filename)

    # Extract sections of config file.
    model_params_section = cfg["model_params"]
    solver_params_section = cfg["solver_params"]

    # Read the cochlea transmission line constants.
    ctl_constants = CochleaTransmissionLineConstants(
        ;
        (Pair(Symbol(k), v) for (k, v) in model_params_section["transmission_line"])...
    )

    # Read the stimulus function type.
    stimulus = load_stimulus(model_params_section["stimulus"])

    solver_params = SolverParams(
        # Read initial state.
        u0_value = solver_params_section["u0_value"],

        # Read the time span of simulation.
        tspan = solver_params_section["tspan"],

        # Read sample rate to be used by the solver. If not found, an empty array is used to not sample.
        saveat = get(solver_params_section, "saveat", []),
    )

    (ctl_constants, stimulus, solver_params)
end

function main()

    # Check that a file name was provided
    if length(ARGS) < 1
        println("Pass parameter YAML file as first argument.")
        exit(1)
    end

    config_filename = ARGS[1]

    ctl_constants, stimulus, solver_params = load_paramters(config_filename)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    u0 = repeat(solver_params.u0_value, outer=ctl_constants.n+1)
    u0_history(
        ::CochleaModelParams,
        ::Float64,
        ;
        idxs=nothing,
    ) =
        if idxs == nothing
            u0
        else
            u0[idxs]
        end

    problem = DDEProblem(
        cochlea_transmission_line!,
        u0,
        u0_history,
        solver_params.tspan,
        model_params,
    )

    algorithm = MethodOfSteps(Tsit5())

    simulation_time = @elapsed solution = solve(problem, saveat=solver_params.saveat, algorithm)
    @show simulation_time

    # TODO: Figure out how to save the solution. Use the method sketched in
    #       scratch/serialize.jl
end

# Only run if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
