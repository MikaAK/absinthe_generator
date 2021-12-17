defmodule Mix.Tasks.Absinthe.Gen do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Lists help for absinthe.gen. commands"
  @moduledoc AbsintheGenerator.moduledoc()

  def run(_args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen")

    Mix.Task.run("help", ["--search", "absinthe.gen."])
  end
end

