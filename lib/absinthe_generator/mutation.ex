defmodule AbsintheGenerator.Mutation do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    mutation_name: Definitions.query_namespace(),
    moduledoc: Definitions.moduledoc(),
    mutations: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.Schema.Field`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate mutation files to be imported
  into the `schema.ex`

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator.FileWriter

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

  @impl AbsintheGenerator.FileWriter
  def file_path(%AbsintheGenerator.Mutation{
    app_name: app_name,
    mutation_name: mutation_name,
  }), do: "./lib/#{Macro.underscore(app_name)}/schema/mutations/#{Macro.underscore(mutation_name)}.ex"

  def run(%AbsintheGenerator.Mutation{} = mutation_struct) do
    AbsintheGenerator.ensure_list_of_structs(
      mutation_struct.mutations,
      AbsintheGenerator.Schema.Field,
      "mutations"
    )

    mutation_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = mutation_struct
      |> Map.from_struct
      |> Map.to_list

    "absinthe_schema_mutation"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
