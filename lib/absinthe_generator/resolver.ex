defmodule AbsintheGenerator.Resolver do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    resolver_name: [type: :string, required: true, doc: "name of the resolver"],
    moduledoc: Definitions.moduledoc(),
    resolver_functions: [
      type: {:list, :string},
      default: [],
      doc: "Resolver functions to inject in, these are just inserted right into the resolver"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate resolver files which
  are then used in the mutations/queries/subscriptions

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @enforce_keys [:app_name, :resolver_name]
  defstruct @enforce_keys ++ [
    :moduledoc,
    resolver_functions: []
  ]

  @type t :: %AbsintheGenerator.Resolver{
    app_name: String.t,
    resolver_name: String.t,
    moduledoc: String.t,
    resolver_functions: list(String.t)
  }

  def run(%AbsintheGenerator.Resolver{} = resolver_struct) do
    assigns = resolver_struct
      |> Map.from_struct
      |> Map.to_list

    resolver_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    "absinthe_resolver"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
