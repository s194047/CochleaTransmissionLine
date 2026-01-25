using CochleaTransmissionLine

using DelayDiffEq
using JLD2
using DataInterpolations

function main()
    # Read config filename from command line arguments.
    if length(ARGS) < 1
        println("Pass parameter YAML file as first argument.")
        exit(1)
    end
    config_filename = ARGS[1]

    # Load parameters from config file.
    println("Loading parameters from config file: $config_filename")
    (; ctl_constants, stimulus, solver_params, data_filename, metadata) = load_parameters(config_filename)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    # Define the initial state and history function.
    u0, u0_history = make_initial_conditions(solver_params, ctl_constants.n)

    # Define the DDE problem.
    problem = DDEProblem(
        cochlea_transmission_line!,
        u0,
        u0_history,
        solver_params.tspan,
        model_params,
    )

    # Choose the solver algorithm.
    algorithm = MethodOfSteps(Tsit5())

    # Run the simulation and log the time taken.
    println("Starting simulation...")
    simulation_time = @elapsed solution = solve(problem, saveat=solver_params.saveat, algorithm)
    println("Simulation completed in $(simulation_time) seconds.")

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
