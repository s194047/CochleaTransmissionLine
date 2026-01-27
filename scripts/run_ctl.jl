using CochleaTransmissionLine

using DelayDiffEq
using JLD2
using DataInterpolations
using TimeZones

function run_simulation(
    differential_equation::Function,
    u0::Vector{Float64},
    u0_history::Function,
    tspan::Union{Tuple{Float64, Float64}, Vector{Float64}},
    model_params::CochleaModelParams,
    solver_params::SolverParams,
)
    # Define the DDE problem.
    problem = DDEProblem(
        differential_equation,
        u0,
        u0_history,
        tspan,
        model_params,
    )

    # Choose the solver algorithm.
    algorithm = MethodOfSteps(Tsit5())

    # Run the simulation and log the time taken.
    println("Starting simulation...")
    start_timestamp = now(localzone())
    duration_seconds = @elapsed solution = solve(problem, saveat=solver_params.saveat, algorithm)
    println("Simulation completed in $(duration_seconds) seconds.")

    (solution, start_timestamp, duration_seconds)
end

function main()
    # Read config filename from command line arguments.
    if length(ARGS) < 1
        println("Pass parameter YAML file as first argument.")
        exit(1)
    end
    parameters_filename = ARGS[1]

    # Read data output filename from command line arguments.
    if length(ARGS) < 2
        println("Pass data output filename as second argument.")
        exit(1)
    end
    data_filename = ARGS[2]

    # Load parameters from config file.
    println("Loading parameters from config file: $parameters_filename")
    (; ctl_constants, stimulus, solver_params, metadata) = load_parameters(parameters_filename)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    # Define the initial state and history function.
    u0, u0_history = make_initial_conditions(solver_params, ctl_constants.n)

    # Run the simulation.
    solution, start_timestamp, duration_seconds = run_simulation(
        cochlea_transmission_line!,
        u0,
        u0_history,
        solver_params.tspan,
        model_params,
        solver_params,
    )

    # Update metadata with simulation info.
    metadata["duration_seconds"] = duration_seconds
    metadata["start_timestamp"] = start_timestamp

    # Save the solution to disk.
    println("Saving solution to $data_filename...")
    mkpath(dirname(data_filename))
    jldsave(
        "$data_filename";
        solution.t,
        solution.u,
        metadata,
    )
    println("Solution saved successfully.")
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
