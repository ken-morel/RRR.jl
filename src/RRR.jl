module RRR
using Sockets

include("./repl.jl")
include("./server.jl")

const RRR_SOCKET = "/tmp/rrr.sock"

function (@main)(_)
    run(server(), RRR_SOCKET)
end


end # module RRR
