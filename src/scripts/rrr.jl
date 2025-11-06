session_module = Module()

while !eof(stdin)
    sentinel = strip(readline(stdin))
    if sentinel == "kill"
        break
    end
    isempty(sentinel) && break

    code_to_run = IOBuffer()
    while !eof(stdin)
        line = readline()
        if strip(line) == sentinel
            break
        else
            println(code_to_run, line)
        end
    end


    code_string = String(take!(code_to_run))[begin:(end-1)]

    try
        expr = Meta.parse(code_string)
        result = Core.eval(session_module, expr)
        if !isnothing(result)
            show(stdout, "text/plain", result)
        end
    catch e
        Base.showerror(stdout, e, Base.catch_backtrace())
    finally
        println()
        println(sentinel)
        flush(stdout)
    end
end
println()
