using JLD2
using TimeZones
using Plots
using Sound

using CochleaTransmissionLine

t, u, metadata = load("data/test3.jld2", "t", "u", "metadata")

interp_sample_rate = 44100.0

(; t_values, u_values, du_values) = interpolate_signal(t, u, interp_sample_rate, compute_derivative=true, ignore_seconds_start=0.001, ignore_seconds_end=0.001)

plot(t_values, u_values[:, 1001])
#soundsc(u_values[:, 1001], interp_sample_rate)
#soundsc(u_values[:, 101], interp_sample_rate)
