using JLD2
using Plots
using TimeZones

#backend(:pyplot)

function main()
    # Read data filename.
    if length(ARGS) < 1
        println("Pass JLD2 data file as first argument.")
        exit(1)
    end
    data_filename = ARGS[1]
    if length(ARGS) < 2
        println("Pass evaluation period as second argument.")
        exit(1)
    end
    evaluation_period = parse(Float64, ARGS[2])
    if length(ARGS) <3
        println("Pass ignored start indices as third argument.")
        exit(1)
    end
    ignored_start_idxs = parse(Int64, ARGS[3])
    if length(ARGS) <3
        println("Pass ignored end indices as fourth argument.")
        exit(1)
    end
    ignored_end_idxs = parse(Int64, ARGS[4])

    t, u, metadata = load(data_filename, "t", "u", "metadata")
    u = stack(u, dims=1)

    n = metadata["model_constants"]["n"]

    y = u[:, 1:2:end]
    v = u[:, 2:2:end]

    t_analysis_start = t[end] - evaluation_period
    analysis_start_idx = findfirst(t .>= t_analysis_start)

    t_analysis = t[analysis_start_idx:end]
    y_analysis = y[analysis_start_idx:end, :]
    v_analysis = v[analysis_start_idx:end, :]

    osc_idxs = ignored_start_idxs:n-ignored_end_idxs

    p = heatmap(
        t_analysis,
        osc_idxs,
        (y_analysis[:, osc_idxs])',
    )
    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
