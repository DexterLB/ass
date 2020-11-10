defmodule AssTest do
  use ExUnit.Case
  doctest Ass

  test "greets the world" do
    assert Ass.hello() == :world
  end
end
