using CochleaTransmissionLine

using YAML
using DelayDiffEq
using JLD2
using DataInterpolations
using WAV

# TODO: Consider once more to save and load the solution
#       rather than t and u with interpolations for better accuracy.

function main()
    # Read config filename from command line arguments.
    if length(ARGS) < 1
        println("Pass parameter YAML file as first argument.")
        exit(1)
    end
    config_filename = ARGS[1]

    # Load parameters from config file.
    println("Loading parameters from config file: $config_filename")
    ctl_constants, stimulus, solver_params, data_filename, metadata = load_parameters(config_filename)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    # Define the initial state and history function.
    # Ensure that either u0_value or previous_solution_filename is provided.
    if isnothing(solver_params.u0_value) && isnothing(solver_params.previous_solution_filename)
        println("Pass either u0 value or previous solution filename.")
        exit(1)
    end
    if !isnothing(solver_params.u0_value)
        println("u0 value specified: $(solver_params.u0_value)")
        println("Setting all CP initial conditions and histories to this value.")
        u0 = repeat(solver_params.u0_value, outer=ctl_constants.n+1)
        u0_history = (::CochleaModelParams, ::Float64; idxs=nothing) ->
        if isnothing(idxs)
            u0
        else
            u0[idxs]
        end
        println("Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
    else
        println("No u0 value specified. Loading previous solution from $(solver_params.previous_solution_filename).")
        if !isfile(solver_params.previous_solution_filename)
            println("Previous solution file not found: $(solver_params.previous_solution_filename)")
            exit(1)
        end
        previous_t, previous_u = load(solver_params.previous_solution_filename, "t", "u")
        println("Setting all CP initial conditions to the last state in the previous solution.")
        u0 = previous_u[end]
        u0_history = let
            println("Previous solution timespan: ($(previous_t[1]), $(previous_t[end]))")
            println("Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
            t_offset = solver_params.tspan[1] - previous_t[end]
            println("Shifting previous solution by $t_offset seconds to align with the current simulation.")
            previous_t_shifted = previous_t .+ t_offset
            interpolator = CubicSpline(previous_u, previous_t_shifted)
            println("Defining history function using interpolation of the previous solution.")
            (::CochleaModelParams, t::Float64; idxs=nothing) ->
                if isnothing(idxs)
                    interpolator(t)
                else
                    interpolator(t)[idxs]
                end
        end
    end

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
