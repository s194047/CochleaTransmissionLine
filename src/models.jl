function cochlea_transmission_line!(
    du::Vector{Float64},
    u::Vector{Float64},
    u_history, # History function
    param::CochleaTransmissionLineParam,
    t::Float64,
)
    dy, dv = @views du[1:2:end], du[2:2:end]
    y, v = @views u[1:2:end], u[2:2:end]

    n = param.n
    x = param.x
    m, d, s = param.m, param.d, param.s
    c = param.c
    τ = param.τ

    history_broadcast_wrapper(param, t, idxs) = u_history(param, t, idxs=idxs)
    y_history = history_broadcast_wrapper.(Ref(param), t .- τ.(x), 1:2:2n-1)

    g = d.(x, v) .* v - s.(x) .* (y + c.(x, v) .* y_history)

    dy .= v
    dv .= 1 / m * (
        -g
    )

    nothing
end
