using CochleaTransmissionLine

using TimeZones
using JLD2
using CairoMakie

t, u, metadata = load("data/zero_stimulus_1s.jld2", "t", "u", "metadata")
u = stack(u, dims=1)
#plot(100:900, oscillator_rotation_frequency(t, u)[100:900])
plot(1:1001, oscillator_winding_frequency(t, u)[1:1001])
