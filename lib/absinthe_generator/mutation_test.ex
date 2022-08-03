defmodule AbsintheGenerator.MutationTest do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    mutation_name: Definitions.query_namespace(),
    mutation_tests: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.TestDescribe`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate mutation test files

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator
  @behaviour AbsintheGenerator.FileWriter

  @enforce_keys [:app_name, :mutation_name]
  defstruct @enforce_keys ++ [
    mutation_tests: []
  ]

  @type t :: %AbsintheGenerator.MutationTest{
    app_name: String.t,
    mutation_name: String.t,
    mutation_tests: list(AbsintheGenerator.TestDescribe.t)
  }

  @impl AbsintheGenerator.FileWriter
  def file_path(%AbsintheGenerator.MutationTest{
    app_name: app_name,
    mutation_name: mutation_name,
  }), do: "./test/#{Macro.underscore(app_name)}/schema/mutations/#{Macro.underscore(mutation_name)}_test.exs"

  @impl AbsintheGenerator
  def run(%AbsintheGenerator.MutationTest{} = mutation_test_struct) do
    AbsintheGenerator.ensure_list_of_structs(
      mutation_test_struct.mutation_tests,
      AbsintheGenerator.TestDescribe,
      "mutation_tests"
    )

    mutation_test_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = [
      app_name: Macro.camelize(mutation_test_struct.app_name),
      module_name: "Mutations.#{Macro.camelize(mutation_test_struct.mutation_name)}",
      tests: mutation_test_struct.mutation_tests
    ]

    "absinthe_schema_test"
      |> AbsintheGenerator.template_path("exs")
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
