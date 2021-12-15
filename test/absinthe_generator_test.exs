defmodule AbsintheGeneratorTest do
  use ExUnit.Case
  doctest AbsintheGenerator

  test "greets the world" do
    assert AbsintheGenerator.hello() == :world
  end
end
