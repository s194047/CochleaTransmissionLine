using JLD2
using Plots
using DSP

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

    t, u = load(data_filename, "t", "u")
    u = stack(u, dims=1)
    y = u[:,1:2:end]
    v = u[:,2:2:end]

    t_analysis_start = t[end] - evaluation_period
    analysis_start_idx = findfirst(t .>= t_analysis_start)

    t_analysis = t[analysis_start_idx:end]
    y_analysis = y[analysis_start_idx:end, :]
    v_analysis = v[analysis_start_idx:end, :]

    v_amplitudes = maximum(v_analysis, dims=1)[:]

    v_ref = 1e-6
    v_amplitudes_db = amp2db.(v_amplitudes ./ v_ref)

    osc_idxs = 0:size(v, 2) - 1

    p = plot(osc_idxs, v_amplitudes_db)
    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
