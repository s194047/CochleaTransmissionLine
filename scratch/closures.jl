using Parameters

f_def(x, a, b) = a + b + x
g_def(y, a, b) = a * b * y

h_def = (a, b) -> (x) -> a + b + x

@with_kw struct SimulationParams
    # Some parameter
    a::Int64

    # Some other parameter
    b::Int64
end

s_params = SimulationParams(a = 42, b = 43)

h = let
    @unpack_SimulationParams(s_params)
    h_def(a, b)
end


f, g =
let a = 2,
    b = 3

    f = x -> f_def(x, a, b)
    g = y -> g_def(y, a, b)
    f, g
end
println(f(10))
println(g(10))
println(h(10))
