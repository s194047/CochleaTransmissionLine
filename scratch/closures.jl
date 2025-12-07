f, g =
let a = 2,
    b = 3

    f = x -> a + b + x
    g = y -> a * b * y
    f, g
end
println(f(10))
println(g(10))

