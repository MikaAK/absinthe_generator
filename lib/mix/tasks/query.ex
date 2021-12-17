defmodule Mix.Tasks.Absinthe.Gen.Query do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe query schema and inserts the record in the base schema.ex"

  @moduledoc """
  Generates ABSINTHE QUERY
  """

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.query")
  end
end
