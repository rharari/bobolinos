defmodule HttpServer do

    def start(port) do
        IO.puts("server start")
        {:ok, sock} = :gen_tcp.listen(port, [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, false}])
        case getInitPath() do
            {:found, www} -> process(sock, 0)
            {:notfound, _} -> {:error, "Sorry, cant find static path 'www'. Something is missing in your deployment."}
        end
    end

    defp process(sock, n) do
        # IO.puts(to_string(n) <> " --------------------------------------------------------------")
        {:ok, conn} = :gen_tcp.accept(sock)
        {:ok, bin} = do_recv(conn)
        IO.puts(bin)
        :gen_tcp.send(conn, response("Hello World"))
        :ok = :gen_tcp.close(conn)
        process(sock, n+1)
    end

    def getInitPath() do
        {:ok, s} = File.cwd()
        case File.dir?(s <>  "/lib2/www") do
           true -> s  <> "/lib/www"
           false -> locatewww(s, File.ls(s))
        end
    end

    def locatewww(base, {:ok, []}) do
        {:notfound, base}
    end
    def locatewww(base, {:ok, [h|t]}) do
        newbase = base <> "/" <> h
        case File.dir?(newbase) do
            true ->
                case h == "www" do
                    true ->
                        {:found, newbase} # found wwwally!
                    false ->
                        case locatewww(newbase, File.ls(newbase)) do # introspect this dir
                            {:found, www} -> {:ok, www} # found www
                            {:notfound, _} -> locatewww(base, {:ok, t}) # and keep going
                         end
                end
            false -> locatewww(base, {:ok, t}) # np, keep going
        end
    end

    def do_recv(sock) do
        case :gen_tcp.recv(sock, 0) do
            {:ok, b} -> {:ok, b}
            {:error, :closed} -> {:ok, ""}
        end
    end

    def response(str) do
        "HTTP/1.0 200 OK\nContent-Type: text/html\nContent-Length: " <> to_string(byte_size(str)) <> "\n\n" <> str
    end

end