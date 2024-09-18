defmodule NexREPL do
  @moduledoc """
  An implementation of the nREPL server protocol in Elixir.
  """

  @doc """
  Starts the nREPL server.

  ## Examples

      iex> NexREPL.start_server()
      {:ok, pid}

  """
  def start_server(opts \\ []) do
    {server_opts, _gen_server_opts} = Keyword.split(opts, [:port])
    NexREPL.Server.start_link(server_opts)
  end
end
