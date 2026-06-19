# Taken from https://gitlab.gbar.dtu.dk/bepp/bsc_mikkel_berrig/

using KernelDensity

function surprise(p::Float64)
    x = -p*log2(p)
    return ifelse(isnan(x),0.,x)
end
function entropy(xs::Vector{Float64})
    U = kde(xs[abs.(xs).<typemax(Int32)/2])
    A = U.x[2]-U.x[1]
    P = sum(U.density[:])*A
    return sum(surprise.(U.density[:]))*A/P
end
function joint_entropy(xs::Vector{Float64}, ys::Vector{Float64})
    U = kde((xs[abs.(xs).<typemax(Int32)/2],
             ys[abs.(ys).<typemax(Int32)/2]))
    A = (U.x[2]-U.x[1]) * (U.y[2]-U.y[1])
    P = sum(U.density[:])*A
    return sum(surprise.(U.density[:]))*A/P
end
function conditional_entropy(xs::Vector{Float64}, ys::Vector{Float64})
    return joint_entropy(xs,ys) - entropy(ys)
end
function mutual_information(xs::Vector{Float64}, ys::Vector{Float64})
    return entropy(xs) + entropy(ys) - joint_entropy(xs,ys)
end
function mutual_information(xs::Vector{Float64}, ys::Matrix{Float64})
    return [mutual_information(xs,ys[i,:]) for i in 1:size(ys,1)]
end

function mutual_information_matrix(xs::Matrix{Float64})
    N = size(xs,1)
    M = zeros(N,N)
    for i in 2:N
        for j in 1:i-1
            M[i,j] = mutual_information(xs[i,:],xs[j,:])
            M[j,i] = M[i,j]
        end
    end
    return M
end

function observe_percent_false(xs::Vector{Float64}, ys::Vector{Float64})
    minxy = minimum([xs;ys])
    maxxy = maximum([xs;ys])
    Avg = (minxy+maxxy)/2
    bounds = ((minxy,maxxy).-Avg).*1.3.+ Avg

    P = kde(xs[abs.(xs).<typemax(Int32)/2],boundary=bounds)
    Q = kde(ys[abs.(ys).<typemax(Int32)/2],boundary=bounds)

    Umin = minimum.(zip(P.density[:],Q.density[:]))
    pmin = sum(Umin)
    if pmin == 0.
        return 0.
    end
    return pmin/(sum(P.density[:])+sum(Q.density[:]))
end
function observe_percent_false(xs::Matrix{Float64}, ys::Matrix{Float64})
    return [observe_percent_false(xs[i,:],ys[i,:]) for i in 1:size(xs,1)]
end

function moments_of_distribution(xs::Vector{Float64}, n::Int64)
    U = kde(xs[abs.(xs).<typemax(Int32)/2])
    A = U.x[2]-U.x[1]
    p = sum(U.density[:])
    μₙ= [sum(U.x.^i .* U.density[:])/p for i in 1:n]
    return μₙ
end
function moments_of_distribution(xs::Matrix{Float64}, n::Int64)
    return mapslices((v)->moments_of_distribution(v,n),xs,dims=[2])
end
