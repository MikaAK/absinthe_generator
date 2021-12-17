defmodule Mix.Tasks.Absinthe.Gen.Resolver do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe resolver"

  @moduledoc """
  Generates ABSINTHE RESOLVER
  """

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.resolver")
  end
end

