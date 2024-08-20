defmodule NexREPLTest do
  use ExUnit.Case
  doctest NexREPL

  test "greets the world" do
    assert NexREPL.hello() == :world
  end
end
