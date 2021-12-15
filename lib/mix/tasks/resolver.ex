defmodule Mix.Tasks.Absinthe.Gen.Resolver do
  use Mix.Task

  @shortdoc "Generates an absinthe resolver"

  @moduledoc """
  Generates ABSINTHE RESOLVER
  """

  def run(args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen.resolver")
  end
end

