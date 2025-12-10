using DSP

function cochlea_transmission_line!(
    du::Vector{Float64},
    u::Vector{Float64},
    u_history, # History function
    solver_params::CochleaSolverInputParams,
    t::Float64,
)
    # Define views for state and derivative of the
    # transverse displacement y and transverse velocity v
    dy, dv = @views du[1:2:end], du[2:2:end]
    y, v = @views u[1:2:end], u[2:2:end]

    # Extract parameters
    (; ctl_constants, ctl_params, ctl_functions) = solver_params
    (; n, m, v_ref, fluid_CP_β) = ctl_constants
    (; x_norm_positions, τ_values, s_values, inv_M) = ctl_params
    (; d, c) = ctl_functions

    # Wrap history function and evaluate delayed values of y
    history_broadcast_wrapper(p, t, idxs) = u_history(p, t, idxs=idxs)
    y_delayed = history_broadcast_wrapper.(
        Ref(solver_params),
        t .- τ_values,
        1:2:2n+1,
    )

    # Calculate decibel value of v
    v_db = amp2db.(abs.(v ./ v_ref))

    # Calculate the force from the intrinsic dynamics of the CP
    g = d.(0:n, v_db) .* v +
        s_values .* (y + c.(0:n, v_db) .* y_delayed)

    # Build the stimulus vector
    b = [stimulus(t); zeros(n - 1); 0.0] # should be apex]

    dy .= v
    dv .= 1 / m * (
        -g +
        inv_M * (
            -fluid_CP_β .* g +
            b
        )
    )

    nothing
end
