defmodule GrubTest do
  use ExUnit.Case
  doctest Grub

  test "greets the world" do
    assert Grub.hello() == :world
  end
end
