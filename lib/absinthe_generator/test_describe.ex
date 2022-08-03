defmodule AbsintheGenerator.TestDescribe do
  @definition [
    describe_name: [type: :string, doc: "describe block text for the test", required: true],
    setup: [type: :string, doc: "setup block for the test"],
    setup_all: [type: :string, doc: "setup_all block for the test"],

    tests: [
      type: {:list, :non_empty_keyword_list},
      doc: "Tests to generate within TestDescribe, following `AbsintheGenerator.TestDescribe.TestEntry`"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate test files which
  are then used in the mutation & query tests

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @enforce_keys [:describe_name, :tests]
  defstruct [:setup, :setup_all | @enforce_keys]

  @type t :: %AbsintheGenerator.TestDescribe{
    describe_name: String.t,
    setup: String.t,
    setup_all: String.t,
    tests: list(AbsintheGenerator.TestDescribe.TestEntry.t),
  }

  defmodule TestEntry do
    @enforce_keys [:function, :description]

    defstruct [
      :function,
      :description,
      params: [],
      pre_block: ""
    ]

    @type t :: %AbsintheGenerator.TestDescribe.TestEntry{
      description: String.t,
      params: list(String.t),
      function: String.t,
      pre_block: String.t
    }
  end

  def definitions, do: @definition

  def maybe_build_test_entry_params_list(%{params: params}) do
    maybe_build_test_entry_params_list(params)
  end

  def maybe_build_test_entry_params_list(nil) do
    ""
  end

  def maybe_build_test_entry_params_list(params) do
    param_entries = params |> Enum.map(&"#{&1}: #{&1}") |> Enum.join(", ")

    ", %{#{param_entries}}"
  end
end
