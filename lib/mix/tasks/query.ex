defmodule Mix.Tasks.Absinthe.Gen.Query do
  use Mix.Task

  @shortdoc "Generates an absinthe query schema and inserts the record in the base schema.ex"

  @moduledoc """
  Generates ABSINTHE QUERY
  """

  def run(args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen.query")
  end
end
