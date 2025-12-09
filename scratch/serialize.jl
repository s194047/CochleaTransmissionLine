struct Params
    i::Int64
end

struct ParamsWithCalc
    params::Params
    j::Int64
end

struct SolverFunctions
    d::Function
    c::Function
    stimulus::Function
end

struct SolverParams
    p2::ParamsWithCalc
    functions::SolverFunctions
end


struct SolverOutput
    ...
    ...
    ...
    p::SolverParams
    ...
end

const makeSolverParams(p2::SolverParams) =
    SolverParams(p2 = p2,

const save_result(SolverParams)
