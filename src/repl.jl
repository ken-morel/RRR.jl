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

function evaluate(r::Repl, conn)
    # Read the sentinel and code directly from the client connection
    sentinel = strip(readline(conn))
    code_buffer = IOBuffer()
    while !eof(conn)
        line = readline(conn)
        strip(line) == sentinel && break
        println(code_buffer, line)
    end
    code_to_run = String(take!(code_buffer))[begin:(end-1)]

    # Send the code to the REPL process
    println(r.process, sentinel)
    println(r.process, code_to_run)
    println(r.process, sentinel)
    flush(r.process)

    # Asynchronously wait for the response with a timeout
    done = Threads.Condition()
    val = Ref{Any}(nothing)
    err = Ref{Any}(nothing)

    @async begin
        try
            response_buffer = IOBuffer()
            while isopen(r.process)
                text = readline(r.process)
                if strip(text) == sentinel
                    @lock done begin
                        val[] = String(take!(response_buffer))[begin:(end-1)]
                        notify(done)
                    end
                    return
                end
                println(response_buffer, text)
            end
        catch e
            @lock done begin
                err[] = e
                notify(done)
            end
        end
    end

    # Wait for the response or timeout after 120 seconds
    t = Timer(20) do t
        @lock done begin
            val[] = "ERRROR: Command timed out after 20 seconds."
            notify(done)
        end
    end

    # Get the response and write it back to the client
    @lock done wait(done)
    close(t)
    if !isnothing(err[])
        Base.showerror(conn, err[])
    else
        println(conn, val[])
    end
    println(conn, sentinel) # Final sentinel to client
end
