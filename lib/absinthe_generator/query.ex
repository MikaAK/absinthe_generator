defmodule AbsintheGenerator.Query do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    query_name: Definitions.query_namespace(),
    moduledoc: Definitions.moduledoc(),
    queries: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.Schema.Field`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate query files to be imported
  into the `schema.ex`

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator
  @behaviour AbsintheGenerator.FileWriter

  def definitions, do: @definition

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

  @impl AbsintheGenerator.FileWriter
  def file_path(%AbsintheGenerator.Query{
    app_name: app_name,
    query_name: query_name,
  }), do: "./lib/#{Macro.underscore(app_name)}/schema/queries/#{Macro.underscore(query_name)}.ex"

  @impl AbsintheGenerator
  def run(%AbsintheGenerator.Query{} = query_struct) do
    AbsintheGenerator.ensure_list_of_structs(
      query_struct.queries,
      AbsintheGenerator.Schema.Field,
      "queries"
    )

    query_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = query_struct
      |> Map.from_struct
      |> Map.to_list

    "absinthe_schema_query"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
