using OrdinaryDiffEq

struct HarmonicParam
    ω::Float64
end

function harmonic!(du::Vector{Float64}, u::Vector{Float64}, p::HarmonicParam, ::Float64)
    dx, dv = @views du[1], du[2]
    x, v = @views u[1], u[2]

    dx = v
    dv = -p.ω^2 * x
end

function main()
    p = HarmonicParam(1.0)
    u0 = [1.0, 0.0]
    tspan = (0.0, 10.0)

    problem = ODEProblem(harmonic!, u0, tspan, p)
    @show problem

    algorithm = Tsit5()

    solution = solve(problem, alg=algorithm)

    @show solution.t
    @show solution.u
    @show solution.du
end

main()
