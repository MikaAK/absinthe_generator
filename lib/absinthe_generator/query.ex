defmodule AbsintheGenerator.Query do
  @enforce_keys [:app_name, :query_name]
  defstruct @enforce_keys ++ [
    :moduledoc,
    queries: []
  ]

  @type t :: %AbsintheGenerator.Query{
    app_name: String.t,
    query_name: String.t,
    moduledoc: String.t,
    queries: list(AbsintheGenerator.Schema.Field.t)
  }

  def run(%AbsintheGenerator.Query{} = mutation_schema) do
    AbsintheGenerator.ensure_list_of_structs(
      mutation_schema.queries,
      AbsintheGenerator.Schema.Field,
      "queries"
    )

    assigns = mutation_schema
      |> Map.from_struct
      |> Map.to_list

    "absinthe_schema_query"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
