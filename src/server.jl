@kwdef struct Server
    repls::Dict{Symbol,Repl} = Dict{String,Repl}()
end
function server()
    Server()
end
function run(s::Server, sock::String)
    server = listen(sock)
    try
        while true
            conn = accept(server)
            query = readline(conn)
            try
                if query == "create"
                    println("Creating REPL")
                    name = Symbol(readline(conn))
                    template = Symbol(readline(conn))
                    args = Base.shell_split(readline(conn))
                    @show name template args
                    command = if template == :none
                        Cmd(args)
                    else
                        TEMPLATES[template](args)
                    end
                    s.repls[name] = repl(command)
                    println("  Repl created")
                    println(conn, "ok")
                elseif query == "run"
                    println("Running code in repl")
                    name = Symbol(readline(conn))
                    seperator = readline(conn)
                    @show name seperator

                    code = IOBuffer()
                    while true
                        ln = readline(conn)
                        strip(ln) == seperator&&break
                        println(code, ln)
                    end
                    response = evaluate(s.repls[name], String(take!(code)))
                    println("Evaluated command")
                    println(conn, response)
                    println(conn, seperator)
                elseif query == "kill"
                    println("Killing repl")
                    name = Symbol(readline(conn))
                    kill(pop!(s.repls, name))
                elseif query == "quit"
                    try
                        for (_, repl) in s.repls
                            kill(repl)
                        end
                        close(conn)
                        close(server)
                    catch
                    finally
                        return
                    end
                end
            catch e
                println("ERROR: ", e)
                try
                    Base.showerror(conn, e, Base.catch_backtrace())
                catch
                end
            finally
                try
                    flush(conn)
                    close(conn)
                catch
                end
            end
        end
    catch e
        if e isa InterruptException
            println("Exciting gracefully")
        else
            rethrow()
        end
    end
end
