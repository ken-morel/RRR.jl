@kwdef struct Server
    repls::Dict{Symbol,Repl} = Dict{String,Repl}()
end
function server()
    Server()
end
function run(s::Server, sock::String)
    # Ensure the socket is cleaned up on exit
    atexit(() -> isfile(sock) && rm(sock))
    isfile(sock) && rm(sock)

    server = listen(sock)
    println("RRR.jl server listening at '$sock'")
    try
        while true
            conn = accept(server)
            @async begin # Handle each connection asynchronously
                try
                    query = readline(conn)
                    if query == "create"
                        println("Received: create")
                        name = Symbol(readline(conn))
                        template = Symbol(readline(conn))
                        args = Base.shell_split(readline(conn))

                        if haskey(s.repls, name)
                            println(conn, "ERROR: Instance '$name' already exists.")
                        else
                            command =
                                template == :none ? Cmd(args) : TEMPLATES[template](args)
                            s.repls[name] = repl(command)
                            println("  Repl '$name' created.")
                            println(conn, "ok")
                        end

                    elseif query == "run"
                        println("Received: run")
                        name = Symbol(readline(conn))
                        if haskey(s.repls, name)
                            # The evaluate function now handles reading the rest of the request from the connection
                            evaluate(s.repls[name], conn)
                            println("  Command evaluated in '$name'.")
                        else
                            println(conn, "ERROR: Instance '$name' does not exist.")
                        end

                    elseif query == "kill"
                        println("Received: kill")
                        name = Symbol(readline(conn))
                        if haskey(s.repls, name)
                            kill(pop!(s.repls, name))
                            println(conn, "Instance '$name' killed successfully.")
                            println("  Repl '$name' killed.")
                        else
                            println(conn, "ERROR: Instance '$name' does not exist.")
                        end

                    elseif query == "quit"
                        println("Received: quit")
                        for (name, repl) in s.repls
                            kill(repl)
                            println("  Repl '$name' killed.")
                        end
                        close(server)
                        println("Server shut down.")
                        # This will break the `while true` loop and exit
                        return

                    end
                catch e
                    println("ERROR: ", sprint(showerror, e))
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
            end # end @async
        end
    catch e
        if !(e isa InterruptException || e isa Base.IOError)
            rethrow()
        end
    finally
        println("\nServer exited.")
    end
end
