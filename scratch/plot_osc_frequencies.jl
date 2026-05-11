using CochleaTransmissionLine

using TimeZones
using JLD2
using CairoMakie

# Edit this to show the effect of longer initial conditions.
length_str = "100s"

t, u, metadata = load("data/solver_params_1s_initial_$length_str.jld2", "t", "u", "metadata")
u = stack(u, dims=1)
#plot(100:900, oscillator_rotation_frequency(t, u)[100:900])
f = Figure()
ax = Axis(f[1, 1], yscale=log10)
plot!(ax, 1:1001, (abs.(oscillator_rotation_frequency(t, u)) ./ 2π)[1:1001])
ax.xlabel = "Oscillator index"
ax.ylabel = "Rotation frequency / Hz"
ax.title = "$length_str initial conditions"
display(f)
