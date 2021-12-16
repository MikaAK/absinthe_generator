defmodule AbsintheGenerator.Mutation do
  @moduledoc """
  We can utilize this module to generate
  """

  @enforce_keys [:app_name, :mutation_name]
  defstruct @enforce_keys ++ [
    :moduledoc,
    mutations: []
  ]

  @type t :: %AbsintheGenerator.Mutation{
    app_name: String.t,
    mutation_name: String.t,
    moduledoc: String.t,
    mutations: list(AbsintheGenerator.Schema.Field.t)
  }

  def run(%AbsintheGenerator.Mutation{} = mutation_schema) do
    AbsintheGenerator.ensure_list_of_structs(
      mutation_schema.mutations,
      AbsintheGenerator.Schema.Field,
      "mutations"
    )

    assigns = mutation_schema
      |> Map.from_struct
      |> Map.to_list

    "absinthe_schema_mutation"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
