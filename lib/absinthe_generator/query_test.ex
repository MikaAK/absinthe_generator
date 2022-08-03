defmodule AbsintheGenerator.QueryTest do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    query_name: Definitions.query_namespace(),
    query_tests: [
      type: {:list, :keyword_list},
      doc: "List of %`AbsintheGenerator.TestDescribe`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate query test files

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator
  @behaviour AbsintheGenerator.FileWriter

  @enforce_keys [:app_name, :query_name]
  defstruct @enforce_keys ++ [
    query_tests: []
  ]

  @type t :: %AbsintheGenerator.QueryTest{
    app_name: String.t,
    query_name: String.t,
    query_tests: list(AbsintheGenerator.TestDescribe.t)
  }

  @impl AbsintheGenerator.FileWriter
  def file_path(%AbsintheGenerator.QueryTest{
    app_name: app_name,
    query_name: query_name,
  }), do: "./test/#{Macro.underscore(app_name)}/schema/queries/#{Macro.underscore(query_name)}_test.exs"

  @impl AbsintheGenerator
  def run(%AbsintheGenerator.QueryTest{} = query_test_struct) do
    AbsintheGenerator.ensure_list_of_structs(
      query_test_struct.query_tests,
      AbsintheGenerator.TestDescribe,
      "query_tests"
    )

    query_test_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = [
      app_name: Macro.camelize(query_test_struct.app_name),
      module_name: "Queries.#{Macro.camelize(query_test_struct.query_name)}",
      tests: query_test_struct.query_tests
    ]

    "absinthe_schema_test"
      |> AbsintheGenerator.template_path("exs")
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
