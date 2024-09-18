defmodule NexREPLTest do
  use ExUnit.Case

  alias NexREPL.Vendor.Bento

  setup do
    port = 7889
    {:ok, server_pid} = NexREPL.start_server(port: port)

    {:ok, client} = :gen_tcp.connect(~c"localhost", port, [:binary, active: false])

    :ok = :gen_tcp.send(client, Bento.encode!(%{"op" => "clone"}))

    {:ok, response} = recv_bencode(client)

    on_exit(fn ->
      IO.puts("Shutting down test server")
      :gen_tcp.close(client)
      Process.exit(server_pid, :normal)
    end)

    %{client: client, session_id: response["new-session"]}
  end

  test "eval operation", %{client: client, session_id: session_id} do
    request = Bento.encode!(%{"op" => "eval", "code" => "1 + 1", "session" => session_id})
    :ok = :gen_tcp.send(client, request)
    {:ok, response} = recv_bencode(client)
    assert response["value"] == "2"
    assert response["status"] == ["done"]
  end

  test "unknown operation", %{client: client} do
    request = Bento.encode!(%{"op" => "unknown", "id" => "test-2"})
    :ok = :gen_tcp.send(client, request)
    {:ok, response} = recv_bencode(client)
    assert response["status"] == ["error", "unknown-op"]
  end

  defp recv_bencode(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        case Bento.decode(data) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
