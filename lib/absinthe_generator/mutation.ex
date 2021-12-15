defmodule AbsintheGenerator.Mutation do
  @enforce_keys [:app_name, :mutation_name]
  defstruct @enforce_keys ++ [
    mutations: []
  ]

  defmodule MutationEntry do
    @enforce_keys [:name, :return_type, :resolver_module_function]
    defstruct @enforce_keys ++ [
      :description,
      arguments: [],
      middleware: []
    ]

    defmodule Argument do
      @enforce_keys [:name, :type]
      defstruct @enforce_keys
    end
  end

  def run(%AbsintheGenerator.Mutation{
    app_name: app_name,
    mutations: mutations
  } = mutation_schema) do
    mutations
    assigns = schema_struct
      |> Map.from_struct
      |> Map.to_list

    "absinthe_mutation"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end
end
