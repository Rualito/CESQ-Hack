using Pkg; Pkg.activate("./mimiq/")
using MimiqCircuits



conn = connect()

circuit = Circuit()

push!(circuit, GateH(), 1)
push!(circuit, GateCX(), 1, 2:10)
push!(circuit, Measure(), 1:10, 1:10)


job = execute(conn, circuit)


res = getresult(conn, job)


draw(circuit)