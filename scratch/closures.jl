f_def(x, a, b) = a + b + x
g_def(y, a, b) = a * b * y

f, g =
let a = 2,
    b = 3

    f = x -> f_def(x, a, b)
    g = y -> g_def(y, a, b)
    f, g
end
println(f(10))
println(g(10))

