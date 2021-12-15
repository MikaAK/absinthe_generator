defmodule Mix.Tasks.Absinthe.Gen.Type do
  use Mix.Task

  @shortdoc "Generates an absinthe type"

  @moduledoc """
  Generates ABSINTHE TYPE
  """

  def run(args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen.type")
  end
end


