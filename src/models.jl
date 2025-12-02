function cochlea_transmission_line!(
    du::Vector{Float64},
    u::Vector{Float64},
    u_history, # History function
    param::CochleaTransmissionLineParam,
    t::Float64,
)
    # Define views for state and derivative of the
    # transverse displacement y and transverse velocity v
    dy, dv = @views du[1:2:end], du[2:2:end]
    y, v = @views u[1:2:end], u[2:2:end]

    # Extract parameters
    n, x = param.n, param.x
    m, d, s, c, τ = param.m, param.d, param.s, param.c, param.τ
    β, inv_M, stimulus = param.β, param.inv_M, param.stimulus

    # Wrap history function and evaluate delayed values of y
    history_broadcast_wrapper(param, t, idxs) = u_history(param, t, idxs=idxs)
    y_delayed = history_broadcast_wrapper.(Ref(param), t .- τ, 1:2:2n-1)

    # Calculate the force from the intrinsic dynamics of the CP
    g = d.(x, v) .* v + s.(x) .* (y + c.(x, v) .* y_delayed)

    # build the stimulus vector
    b = [stimulus(t); zeros(n - 1)]

    dy .= v
    dv .= 1 / m * (
        -g +
        inv_M * (
           β .* g +
           b
        )
    )

    nothing
end
