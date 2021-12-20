defmodule Mix.Tasks.Absinthe.Gen.Type do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe type"

  @moduledoc """
  Generates ABSINTHE TYPE
  """

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.type")
  end
end
