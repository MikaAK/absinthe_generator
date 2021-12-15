defmodule Mix.Tasks.Absinthe.Gen do
  use Mix.Task

  @shortdoc "Lists help for absinthe.gen. commands"
  @moduledoc AbsintheGenerator.moduledoc()

  def run(_args) do
    AbsintheGenerator.ensure_not_in_umbrella!("absinthe.gen")

    Mix.Task.run("help", ["--search", "absinthe.gen."])
  end
end

