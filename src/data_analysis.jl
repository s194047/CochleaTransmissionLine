using SciMLBase: ODESolution

function get_solution_samples(solution::ODESolution, t::Vector{Float64}, deriv=Val{0}; idxs=nothing)
    x = stack(solution(t, deriv, idxs=idxs).u, dims=1)
    t, x
end
function get_solution_samples(solution::ODESolution, fs::Float64, deriv=Val{0}; idxs=nothing)
    t_start, t_end = solution.t[1], solution.t[end]
    t = collect(t_start:1/fs:t_end)
    get_solution_samples(solution, t, deriv, idxs=idxs)
end
