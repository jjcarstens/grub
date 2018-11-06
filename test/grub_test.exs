defmodule NACTest do
  use ExUnit.Case
  doctest NAC

  test "greets the world" do
    assert NAC.hello() == :world
  end
end
