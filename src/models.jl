function cochlea_transmission_line!(
    du::Vector{Float64},
    u::Vector{Float64},
    param::CochleaTransmissionLineParam,
    t::Float64,
)
    dy, dv = @views du[1:2:end], du[2:2:end]
    y, v = @views u[1:2:end], u[2:2:end]

    n = param.n
    x = param.x
    m, d, s = param.m, param.d, param.s
    #inv_M, β = param.inv_M, param.β
    #drive, apex = param.drive, param.apex

    #b = [drive(t); zeros(n-2); apex * v[end]]

    dy .= v
    dv .= 1 / m * (
        (-d(y) .* v - s .* y) #+
        #inv_M * (
        #    β.(x) .* (-d.(x, y) .* v - s.(x, y) .* y) +
        #    b
        #)
    )

    nothing
end
