@kwdef struct Server
    repls::Dict{Symbol,Repl} = Dict{String,Repl}()
end
function server()
    Server()
end
function run(s::Server, sock::String)
    println("Starting server")
    server = listen(sock)
    println("Listening to connections")
    try
        while true
            conn = accept(server)
            @time try
                println("Connection received")
                query = readline(conn)
                @show query
                if query == "create"
                    println("Creating REPL")
                    name = Symbol(readline(conn))
                    template = Symbol(readline(conn))
                    args = Base.shell_split(readline(conn))
                    @show name template args
                    if haskey(s.repls, name)
                        println(conn, "ERRROR: Instance $name already exists")
                        println("  Already exists")
                        continue
                    end
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
                    if !haskey(s.repls, name)
                        println(conn, "ERRRROR: Instance $name does not exist")
                        continue
                    end

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
                    @show name
                    if haskey(s.repls, name)
                        kill(pop!(s.repls, name))
                        println(conn, "Instance killed succesfuly")
                    else
                        println(conn, "Instance does not exist")
                    end
                elseif query == "quit"
                    println("Quiting")
                    try
                        for (_, repl) in s.repls
                            kill(repl)
                        end
                    finally
                        return
                    end
                end
            catch e
                println("ERRROR: ", e)
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
    finally
        try
            rm(sock)
        catch
        finally
            println("Bye")
        end
    end
end
