struct Constants
    i::Int64
end

struct Params
    v::Vector{Float64}
end

struct Functions
    d::Function
    c::Function
    stimulus::Function
end

struct SolverInputParams
    constants::Constants
    params::Params
    functions::Functions
end

struct SolverInputParamsNoFunctions
    constants::Constants
    params::Params
end


struct ODESolution
    ...
    ...
    ...
    p::SolverInputParams
    ...
end

# Before save of ODESolution to disk, replace p with SolverInputParamsNoFunctions
# After load of ODESolution from disk, replace p with SolverInputParams (recalculated functions, or you might have SolverInputParams already)
