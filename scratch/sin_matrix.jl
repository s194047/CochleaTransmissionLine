using FFTW
using Plots

fs = 1e4
tmax = 10.0
t = 0:1/fs:tmax-1/fs

f0_values = [50, 100, 150, 200]
s = sin.(2π .* f0_values' .* t)

time_plot = plot( t, s, xlims=(0, 0.100))

f = fftfreq(length(t), fs)
S = fft(s, 1)

frequency_plot = plot(f, abs.(S), xlims=(0, 250))
