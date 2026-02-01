using DataInterpolations
using Plots

fs = 1000.0

t = -0.60:1/fs:1.60
x = sin.(2π * 1.0 * t)

xi = CubicSpline(x, t, extrapolation=ExtrapolationType.Constant)
xi_ext = CubicSpline(x, t, extrapolation=ExtrapolationType.Constant)

padding_points = 1

t_prepad = t[1] - padding_points/fs:1/fs:t[1] - 1/fs
t_postpad = t[end] + 1/fs:1/fs: t[end] + padding_points/fs

t_zp = [t_prepad; t; t_postpad]

x_zp = [zeros(padding_points); x; zeros(padding_points)]

xi_zp = CubicSpline(x_zp, t_zp, cache_parameters=true, extrapolation=ExtrapolationType.Constant)

t_fine = -1.5:0.001:2.5

plot(t_fine, [xi.(t_fine), xi_zp.(t_fine)])
