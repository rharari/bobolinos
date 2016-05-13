# basic http server to provide static content
defmodule HttpServer do

    # start http server - ex: start(8080)
    def start(port) do
        initPath= getInitPath()
        {:ok, sock} = :gen_tcp.listen(port, [:binary, {:packet, 0}, {:reuseaddr, true}, {:active, false}])
        case initPath do
            {:found, www} ->
                    :ets.new(:http_registry, [:named_table])
                    :ets.insert(:http_registry, {"wwwpath", www}) # store www path
                    process(sock, 0)
            {:notfound, _} -> {:error, "Sorry, cant find static path 'www'. Something is missing in your deployment."}
        end
    end

    # process http requests
    defp process(sock) do
        {:ok, conn} = :gen_tcp.accept(sock)
        {:ok, bin} = do_recv(conn)
        :gen_tcp.send(conn, response(bin))
        :ok = :gen_tcp.close(conn)
        process(sock)
    end

    # get request parameters
    defp do_recv(sock) do
        case :gen_tcp.recv(sock, 0) do
            {:ok, b} -> {:ok, b}
            {:error, :closed} -> {:ok, ""}
        end
    end

    # produce a response content
    defp response(request) do
        [cmd,file|_] = String.split(request, " ")
        case cmd do
          "GET" -> retrieveFile(file)
          _ -> "HTTP/1.0 405 Method Not Allowed"
        end
    end

    # retrieve file content
    def retrieveFile(file) do
        [{_,dir}] = :ets.lookup(:http_registry, "wwwpath")
        case File.read(dir <> file) do
          {:ok, bin} -> "HTTP/1.0 200 OK\nContent-Type: " <>
                         getContentType(String.downcase(file)) <>
                         "\nContent-Length: " <> to_string(byte_size(bin)) <> "\n\n" <> bin
          {:error, _} -> "HTTP/1.0 404 Not Found"
        end
    end

    # retrieve mime type
    defp getContentType(file) do
        cond do
            String.ends_with? file, ".html" -> "text/html; charset=utf-8"
            String.ends_with? file, ".htm" -> "text/html; charset=utf-8"
            String.ends_with? file, ".js" -> "application/javascript; charset=utf-8"
            String.ends_with? file, ".png" -> "image/png"
            String.ends_with? file, ".jpg" -> "image/jpeg"
            String.ends_with? file, ".json" -> "application/json; charset=utf-8"
            String.ends_with? file, ".txt" -> "text/text; charset=utf-8"
            true -> "application/octet-stream"

        end
    end

    # find 'www' path
    defp getInitPath() do
        {:ok, s} = File.cwd()
        case File.dir?(s <>  "/lib/www") do
           true -> {:found, s  <> "/lib/www"}
           false -> locatewww(s, File.ls(s))
        end
    end

    # find www path
    defp locatewww(base, {:ok, []}) do
        {:notfound, base}
    end
    defp locatewww(base, {:ok, [h|t]}) do
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

end