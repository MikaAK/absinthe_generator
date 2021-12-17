defmodule Mix.Tasks.Absinthe.Gen.Mutation do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe mutation schema and inserts the record in the base schema.ex"

  @moduledoc """
  Generates ABSINTHE MUTATION
  """

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.mutation")

    {opts, extra_args} = AbsintheGeneratorUtils.parse_path_opts(args, [
      mutation_name: :string,
      moduledoc: :string
    ])


    AbsintheGeneratorUtils.write_template("./test.ex", "Hello")
  end
end

