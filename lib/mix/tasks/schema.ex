defmodule Mix.Tasks.Absinthe.Gen.Schema do
  use Mix.Task

  @shortdoc "Generates an absinthe schema"

  @moduledoc """
  Generates ABSINTHE SCHEMA
  """

  def run(args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen.schema")
  end
end
