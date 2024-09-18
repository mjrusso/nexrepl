defmodule Mix.Tasks.Nexrepl do
  @moduledoc "A Mix task that starts an nREPL server. Usage: `iex -S mix nexrepl`"
  @shortdoc "Runs an nREPL server for an Elixir application"

  use Mix.Task

  def run(_) do
    Logger.put_module_level(NexREPL, :info)

    NexREPL.start_server()
  end
end
