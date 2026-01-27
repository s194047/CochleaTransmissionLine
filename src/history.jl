using SciMLBase: ODESolution

mutable struct UHistory
    history_function::Union{ODESolution, Function, Nothing}
end

function (u_history::UHistory)(::Any, t::Float64; idxs)
    u_history.history_function(t; idxs=idxs)
end

function forget_history_function(u_history::UHistory)
    u_history.history_function = nothing
end
