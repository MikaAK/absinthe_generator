defmodule AbsintheGenerator.Schema do
  @enforce_keys [:app_name]
  defstruct [
    :app_name,
    :moduledoc,
    pre_middleware: [],
    post_middleware: [],
    queries: [],
    mutations: [],
    subscriptions: [],
    data_sources: [],
    types: []
  ]

  defmodule DataSource do
    @enforce_keys [:source, :query]
    defstruct @enforce_keys

    @type t :: %DataSource{
      source: String.t,
      query: String.t
    }
  end

  defmodule Middleware do
    @enforce_keys [:module, :types]
    defstruct @enforce_keys
  end

  @type t :: %__MODULE__{
    app_name: String.t,
    pre_middleware: list(String.t),
    post_middleware: list(String.t),
    queries: list(String.t),
    mutations: list(String.t),
    subscriptions: list(String.t),
    types: list(String.t),
    data_sources: list(DataSource.t),
  }

  def run(%AbsintheGenerator.Schema{
    data_sources: data_sources,
    pre_middleware: pre_middleware,
    post_middleware: post_middleware,
  } = schema_struct) do
    AbsintheGenerator.ensure_list_of_structs(data_sources, AbsintheGenerator.Schema.DataSource, "data sources")


    assigns = schema_struct
      |> Map.from_struct
      |> Map.put(:middleware, serialize_middleware_assigns(pre_middleware, post_middleware))
      |> Map.to_list

    "absinthe_schema"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end

  defp serialize_middleware_assigns(_pre_middleware, _post_middleware) do
    %{
      everything: [],
      subscription: [],
      mutation: [],
      query: []
    }
  end
end
