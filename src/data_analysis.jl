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

function instantaneous_rotation(z::Matrix{ComplexF64}, dz::Matrix{ComplexF64})
    @. abs(imag(conj(z) * dz)) / abs2(z)
end
function instantaneous_rotation(x::Matrix{Float64}, dx::Matrix{Float64})
    x1, x2 = @views x[:, 1:2:end], x[:, 2:2:end]
    dx1, dx2 = @views dx[:, 1:2:end], dx[:, 2:2:end]

    z = x1 + im * x2
    dz = dx1 + im * dx2

    instantaneous_rotation(z, dz)
end
