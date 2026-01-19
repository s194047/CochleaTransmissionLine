using JLD2
using Plots

function main()
    # Read data filename.
    if length(ARGS) < 1
        println("Pass JLD2 data file as first argument.")
        exit(1)
    end
    data_filename = ARGS[1]
    if length(ARGS) < 2
        println("Pass index as second argument.")
        exit(1)
    end
    osc_idx = parse(Int64, ARGS[2])
    idx = osc_idx * 2 + 1

    t, u = load(data_filename, "t", "u")
    u = stack(u, dims=1)

    p = plot(t, u[:, idx])
    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
