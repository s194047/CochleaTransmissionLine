using CochleaTransmissionLine

using DelayDiffEq
using JLD2
using DataInterpolations
using TimeZones

function run_simulation(
    differential_equation::Function,
    u0::Vector{Float64},
    u0_history,
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

    # Determine the maximum run time based on the maximum delay in the system.
    max_delay = maximum(model_params.ctl_params.τ_values)
    max_run_time = ceil(max_delay, digits=1)
    println("Maximum delay in system: $max_delay seconds.")
    println("Maximum run time per segment: $max_run_time seconds.")

    # Divide the timespan into segments to avoid excessive memory usage.
    intervals = let
        t0, t1 = solver_params.tspan;
        edges = collect(t0:max_run_time:t1);
        edges[end] < t1 && push!(edges, t1);
        [(edges[i], edges[i+1]) for i in 1:length(edges)-1]
    end
    println("Divided total timespan into $(length(intervals)) intervals of $max_run_time seconds each.")

    # Initialize empty arrays for solution t and u and for simulation info metadata.
    # TODO: Consider zipping t and u to named tuples.
    t = Vector{Float64}()
    u = Vector{Vector{Float64}}()
    metadata["duration_seconds_values"] = Vector{Float64}()
    metadata["start_timestamp_values"] = Vector{ZonedDateTime}()

    # Run the simulation in segments.
    for interval in intervals
        println("Running simulation for interval: $interval")
        # Run the simulation for the current interval.
        solution, start_timestamp, duration_seconds = run_simulation(
            cochlea_transmission_line!,
            u0,
            u0_history,
            interval,
            model_params,
            solver_params,
        )

        # Append the results to the overall solution.
        if isempty(t) || solution.t[1] > t[end]
            # This is the first segment or (not expected) the new segment does not start exactly where the previous ended.
            append!(t, solution.t)
            append!(u, solution.u)
        else
            # Avoid duplicating the initial time point of the new segment.
            append!(t, solution.t[2:end])
            append!(u, solution.u[2:end])
        end

        # Update initial conditions and history function for the next interval.
        println("Updating initial conditions for next interval.")
        u0 = solution.u[end]
        u0_history = UHistory(solution)

        # Record simulation info metadata.
        push!(metadata["duration_seconds_values"], duration_seconds)
        push!(metadata["start_timestamp_values"], start_timestamp)

        # FIXME: Remove this when the memory issue is solved.
        # Print the memory size of `solution` for diagnostics
        @show Base.summarysize(solution)
    end

    # Save the solution to disk.
    println("Saving solution to $data_filename...")
    mkpath(dirname(data_filename))
    jldsave(
        "$data_filename";
        t,
        u,
        metadata,
    )
    println("Solution saved successfully.")
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
