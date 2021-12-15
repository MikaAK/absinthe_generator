defmodule Mix.Tasks.Absinthe.Gen.Mutation do
  use Mix.Task

  @shortdoc "Generates an absinthe mutation schema and inserts the record in the base schema.ex"

  @moduledoc """
  Generates ABSINTHE MUTATION
  """

  def run(args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen.mutation")
  end
end

