defmodule MakinaTest do
  use ExUnit.Case
  doctest Makina

  test "greets the world" do
    assert Makina.hello() == :world
  end
end
