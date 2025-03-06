using Pkg; Pkg.activate("./mimiq/")
using MimiqCircuits
using Plots
plotlyjs()

fname = "t11_data.dat"

conn = connect()

function periodic_boundary(a, n)
    if a<1
        return a+n
    elseif a>n
        return a-n
    end
    return a
end

function open_boundary(a,n)
    if a<1
        return 1
    elseif a>n
        return n
    end
    return a
end

#%% Running circuits

n = 45
nsteps = 10

meas_idx = zeros(Int32,(nsteps, n))

# Generating a quantum circuit from cellular automata rules
# 1D chain 

# prepare the state
state_circuit = Circuit()

push!(state_circuit, GateX(), n/2+1|>floor|>Int)
# push!(state_circuit, GateX(), n//2|>floor|>Int)

# execute the qca circuit
qca_circuit = Circuit()

⦿(a) = open_boundary(a, n)

for i ∈ 1:nsteps
    for k ∈ [0, 1]
        for j ∈ 1:n
            if j%2 == k
                a1 = j-1 |> ⦿
                a2 = j+1 |> ⦿
                c0 = j|> ⦿
                # push!(qca_circuit, GateH(), c0)
                # if a1 ≠ c0
                #     push!(qca_circuit, GateCH(), a1, c0)
                # end
                if a2 ≠ c0
                    # push!(qca_circuit, GateCH(), a2, c0)
                    if a1≠c0
                        push!(qca_circuit, GateX(), a1)
                        push!(qca_circuit, GateX(), a2)
                        push!(qca_circuit, control(2, GateH()), a1, a2, c0)
                        push!(qca_circuit, GateX(), a1)
                        push!(qca_circuit, GateX(), a2)
                    end
                end
            end
        end
    end
    meas_idx[i, :] = collect(1:n) .+ n*(i-1)
    push!(qca_circuit, ExpectationValue(GateZ()), 1:n, meas_idx[i, :])
    push!(qca_circuit, VonNeumannEntropy(), n/2|>floor|>Int, n*nsteps+i)
    push!(qca_circuit, BondDim(), 1:n, ((n+1)*nsteps+i):((n+n)*nsteps+i))
    # push!(qca_circuit, BondDim(), n/2|>floor|>Int, (n+1)*nsteps+i)
end

append!(state_circuit, qca_circuit)
# draw(state_circuit)

push!(state_circuit, Measure(), 1:n, 1:n)

println("Executing circuit in the cloud")
job = execute(conn, state_circuit, timelimit=3)

res = getresult(conn, job)

saveproto("t11_results_n=$(n)_nsteps=$(nsteps).pfr", res)
saveproto("t11_circ_n=$(n)_nsteps=$(nsteps).pfc", state_circuit)

println("Saved results")

# values = reshape(res.zstates[1][1:n*nsteps], (n, nsteps)) |> real

# println("Plotting results")
# h1 = heatmap(1:nsteps, 1:n, values)
# # xlims!(1,200)
# p1 = plot(1:nsteps, res.zstates[1][n*nsteps+1:end].|>abs)

# plot(h1, p1, layout=[1,1], size=(800,600))

