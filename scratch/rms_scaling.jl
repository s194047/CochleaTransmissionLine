using Plots

include("../src/data_analysis.jl")

fs = 1e4
t = collect(0:1/fs:10π-1/fs)

freqs = [1.0, 2.0, 3.0, 4.0]
z = exp.(im * freqs' .* t)
u = reduce(hcat, (hcat(real(z[:,j]), imag(z[:,j])) for j in axes(z,2)))

ellipse_scaling = [1e0 1e3 1e0 1e6 1e0 1e-3 1e0 1e0]

u_ellipse = u .* ellipse_scaling


mean_rotation(t, u)

mean_rotation(t, u_ellipse)

mean_rotation(t, u_ellipse, scale_by_rms=true)
