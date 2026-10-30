using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using PythonPlot
using PythonCall

const ignore_idxs = 100

animation = pyimport("matplotlib.animation")

matplotlib.style.use("../paper.mplstyle")
matplotlib.rcParams["savefig.dpi"] = 600

# widths from the LaTeX document.
const column_width_pt = 221.0
const text_width_pt = 452.0

# Conversion factor: 72.27 LaTeX points per 72 Makie (PostScript) points
const latex_pt_per_in = 72.27

# Aspect ratio of plot.
const figure_aspect_ratio = 4 / 3

const n = 1000
const x_apex_value = 0.035

function parse_commandline()::Dict
    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--input-file", "-i"], Dict(
            :help => "JLD2 file containing CTL data.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
        ["--output-file", "-o"], Dict(
            :help => "JLD2 file to store the calculated mutual information.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
        ["--periods", "-p"], Dict(
            :help => "How many periods to include in the animation. If not specified, animate the whole timeframe.",
            :arg_type => Int,
            :metavar => "NUM",
        ),
        ["--virtual-frequency", "-f"], Dict(
            :help => "Virtual frequency to be used for periods calculation for controlling the animation length when no stimulus frequency exists.",
            :arg_type => Float64,
            :metavar => "FREQ",
        ),
        ["--variable", "-v"], Dict(
            :help => "Which variable to plot.",
            :arg_type => String,
            :metavar => "{y,v}",
            :range_tester => ∈(["y", "v"]),
            :required => true,
        )
    )

    parse_args(arg_defs)
end

function n_frames(n_periods::Int, stimulus_frequency::Float64, saveat::Float64)::Int
    Int(n_periods / (stimulus_frequency * saveat))
end

function get_ylim(variable::AbstractMatrix{Float64})::Float64
    sub_matrix = @view variable[:, (ignore_idxs+1):(end-ignore_idxs)]
    max_abs_value = maximum(abs.(sub_matrix))
    if max_abs_value == 0
        return max_abs_value
    end
    p = floor(log10(max_abs_value))
    scale = 10.0^p
    ceil(max_abs_value / scale) * scale
end

function create_animation(variable::AbstractMatrix{Float64}, ylabel_value::String, frames::Int, output_file::String)
    osc_idxs = 0:size(variable, 2) - 1
    max_osc_idx = osc_idxs[end]
    x_apex_mm = x_apex_value * 1e3 # mm
    x_values_mm = x_apex_mm * (osc_idxs ./ max_osc_idx)

    ylim_value = get_ylim(variable)

    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio
    fig = figure(figsize=(fig_width_in, fig_height_in))
    line = plot(x_values_mm, variable[1,:])[0]
    ylim(-ylim_value, ylim_value)
    xlabel("distance from stapes / mm")
    ylabel(ylabel_value)
    ticklabel_format(scilimits=(-3, 6))

    function update(frame)
        # `frame` is 0-indexed (Python) and the matrix needs to be 1-indexed (Julia)
        line.set_ydata(variable[frame+1,:])
    end

    anim = animation.FuncAnimation(fig=fig, init_func=()->(), func=update, frames=frames, interval=20)

    mkpath(dirname(output_file))
    anim.save(filename=output_file, writer="pillow")
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

    variable_map = Dict("y" => y, "v" => v)
    ylabel_map = Dict("y" => "displacement / m", "v" => "velocity / m/s")

    chosen_variable = variable_map[parsed_args["variable"]]
    chosen_ylabel = ylabel_map[parsed_args["variable"]]

    frequency = get(metadata["stimulus"], "frequency", parsed_args["virtual-frequency"])
    periods = parsed_args["periods"]
    frames = !isnothing(periods) ? n_frames(
        periods,
        frequency,
        metadata["solver_params"]["saveat"],
    ) : size(chosen_variable, 1)

    create_animation(chosen_variable, chosen_ylabel, frames, parsed_args["output-file"])
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
