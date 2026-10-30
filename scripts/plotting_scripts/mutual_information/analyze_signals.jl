using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using PythonPlot
import PythonPlot: matplotlib
using Printf

function parse_commandline()::Dict
    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--input-file", "-i"], Dict(
            :help => "JLD2 file containing CTL data.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
    )

    parse_args(arg_defs)
end

function main()
    parsed_args = parse_commandline()

    # JLD2 file with CTL data to load
    println(stderr, "Loading solution from $(parsed_args["input-file"])")
    u, metadata = load(parsed_args["input-file"], "u", "metadata")

    # Stack `u` to have a Matrix{Float64} rather than Vector{Vector{Float64}}
    u = stack(u, dims=1)

    # Extract the displacement and velocity from the solution.
    y = @view u[:, 1:2:end]
    v = @view u[:, 2:2:end]

    black_pairs = [(501, 500), (545, 500), (570, 500), (587, 500), (601, 500)]
    grey_pairs = [(525, 500), (558, 500), (579, 500), (594, 500)]
    # fig, axs = subplots(3,2)
    # for (ax, pair) in zip(axs.flatten(), black_pairs)
    #     ax.scatter(v[:,pair[1]], v[:,pair[2]], s=0.1)
    # end
    # fig, axs = subplots(3,2)
    # for (ax, pair) in zip(axs.flatten(), grey_pairs)
    #     ax.scatter(v[:,pair[1]], v[:,pair[2]], s=0.1)
    # end
    # PythonPlot.show()

    figure()
    plot(v[:, 500])
    PythonPlot.show()
    # for i in 1:1:501#size(v, 1)
    #     clf()
    #     plot(v[i, :])
    #     ylim(-2e-5, 2e-5)
    #     t = @sprintf("%.2f", i*metadata["solver_params"]["saveat"] * 1000)
    #     PythonPlot.title("Row $i, t = $t ms", loc="left")
    #     PythonPlot.pause(0.05)
    # end
    PythonPlot.show()
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
