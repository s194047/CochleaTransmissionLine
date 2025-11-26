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

    dy .= v
    dv .= 1 / m * (
        (-d.(x, v) .* v - s.(x) .* y) #(y + c.(x) * y(t - τ.(x))))
    )

    nothing
end
