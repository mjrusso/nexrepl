defmodule NexREPL.Server do
  use GenServer
  require Logger

  @moduledoc """
  Proof-of-concept implementation of the nREPL server protocol.

  Implementation adapted from: <https://gitlab.com/sasanidas/python-nrepl>

  Also see: <https://nrepl.org/nrepl/building_servers.html>
  """

  alias NexREPL.Vendor.Bento

  # Client API

  @doc """
  Starts the nREPL server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 7888)
    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    Logger.info("nREPL server started on port #{port}")

    case File.write(".nrepl-port", Integer.to_string(port)) do
      :ok ->
        Logger.debug("Wrote .nrepl-port file")

      {:error, reason} ->
        Logger.warning("Failed to write .nrepl-port file: #{reason}")
    end

    send(self(), :accept)
    {:ok, %{socket: socket, port: port, sessions: %{}}}
  end

  @impl true
  def handle_info(:accept, state) do
    {:ok, client} = :gen_tcp.accept(state.socket)
    {:noreply, state, {:continue, {:handle_client, client}}}
  end

  @impl true
  def handle_continue({:handle_client, client}, state) do
    spawn_link(fn -> handle_client(client, state) end)
    send(self(), :accept)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("nREPL server stopping..")

    File.rm(".nrepl-port")

    :ok
  end

  # Client handling

  defp handle_client(client, state) do
    case recv_bencode(client) do
      {:ok, data} ->
        new_state = handle_message(data, client, state)
        handle_client(client, new_state)

      {:error, :closed} ->
        Logger.info("Client disconnected")
    end
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

  defp handle_message(message, client, state) do
    process_message(message, client, state)
  end

  defp process_message(%{"op" => "clone"} = message, client, state) do
    new_session_id = :erlang.make_ref() |> :erlang.ref_to_list() |> to_string()

    new_state =
      put_in(state, [:sessions, new_session_id], state.sessions[message["session"]] || [])

    response =
      Bento.encode!(%{
        "id" => message["id"],
        "new-session" => new_session_id,
        "status" => ["done"]
      })

    :gen_tcp.send(client, response)
    new_state
  end

  defp process_message(%{"op" => "close", "session" => session_id} = message, client, state) do
    new_state = update_in(state.sessions, &Map.delete(&1, session_id))

    response =
      Bento.encode!(%{
        "id" => message["id"],
        "status" => ["done"]
      })

    :gen_tcp.send(client, response)
    new_state
  end

  defp process_message(%{"op" => "describe"} = message, client, state) do
    response =
      Bento.encode!(%{
        "id" => message["id"],
        "ops" => %{
          "clone" => {},
          "close" => {},
          "describe" => {},
          "eval" => {},
          "ls-sessions" => {}
        },
        "versions" => %{
          "nrepl" => %{"major" => 0, "minor" => 6, "incremental" => 0}
        },
        "status" => ["done"]
      })

    :gen_tcp.send(client, response)
    state
  end

  defp process_message(
         %{"op" => "eval", "code" => code, "session" => session_id} = message,
         client,
         state
       ) do
    {response, new_state} =
      try do
        {result, new_bindings} = Code.eval_string(code, state.sessions[session_id] || [])
        new_state = put_in(state, [:sessions, session_id], new_bindings)

        response =
          Bento.encode!(%{
            "id" => message["id"],
            "value" => inspect(result),
            "status" => ["done"]
          })

        {response, new_state}
      rescue
        e ->
          Logger.error("Error evaluating code: #{inspect(e)}")

          response =
            Bento.encode!(%{
              "id" => message["id"],
              "ex" => inspect(e)
            })

          {response, state}
      end

    :gen_tcp.send(client, response)
    new_state
  end

  defp process_message(%{"op" => "ls-sessions"} = message, client, state) do
    response =
      Bento.encode!(%{
        "id" => message["id"],
        "sessions" => Map.keys(state.sessions)
      })

    :gen_tcp.send(client, response)
    state
  end

  defp process_message(message, client, state) do
    Logger.warning("Unhandled message: #{inspect(message)}")

    response =
      Bento.encode!(%{
        "id" => message["id"],
        "status" => ["error", "unknown-op"]
      })

    :gen_tcp.send(client, response)
    state
  end
end
