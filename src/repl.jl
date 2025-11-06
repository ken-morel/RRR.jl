@kwdef struct Repl
    process::Base.Process
end

function repl(cmd::Cmd)
    cmd = Cmd(cmd; dir = joinpath(@__DIR__, "scripts"))
    proc = open(cmd, "r+")
    Repl(proc)
end
function kill(r::Repl)
    println(r.process, "kill")
    readline(r.process)
end

function evaluate(r::Repl, code::String)::String
    sentinel = string("<rrr", rand(UInt), "rrr>")
    println(r.process, sentinel)
    println(r.process, code)
    println(r.process, sentinel)
    flush(r.process)
    response = IOBuffer()
    while true
        text = readline(r.process)
        strip(text) == sentinel && break
        println(response, text)
    end
    String(take!(response))
end

const TEMPLATES = Dict(:jl => a -> `julia $a rrr.jl`, :py => a -> `python $a rrr.py`)
