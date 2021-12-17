defmodule Mix.Tasks.Absinthe.Gen.Schema do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe schema"

  @moduledoc """
  Generates an Absinthe Schema

  ### Options

  - `app_name` - Application name (required)
  - `moduledoc` - module doc to inject
  - `type` - Type modules to utilize (multiple possible)
  - `query` - Query modules to utilize (multiple possible)
  - `mutation` - Mutation modules to utilize (multiple possible)
  - `subscription` - Subscription modules to utilize (multiple possible)
  - `data_source` - List of PG contects to utilize (multiple possible)

  ### Specifying Middleware
  To specify middleware we can utilize the following syntax

  ```bash
  pre_middleware:mutation:AuthMiddleware post_middleware:all:ChangesetErrorFormatter
  ```

  Middleware can be set for `mutation`, `query`, `subscription` or `all` and can
  also be set to either run pre or post resolution using `pre_middleware` or `post_middleware`


  ### Example

  ```bash
  mix absinthe.gen.schema pre_middleware:mutation:MyMiddlwareModule post_middleware:all:MyAllMiddleware
    --app-name MyApp
    --query test
    --query user
    --mutation user
    --mutation session
    --type MyApp
    --moduledoc "this is the test"
    --data-source "EctoSchemas.Cats"
  ```
  """

  @middleware_regex ~r/(pre_middleware|post_middleware):(mutation|query|subscription|all):[a-zA-Z_]+/

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.schema")

    {args, extra_args} = AbsintheGeneratorUtils.parse_path_opts(args, [
      app_name: :string,
      moduledoc: :string,

      type: :keep,
      query: :keep,
      mutation: :keep,
      subscription: :keep,

      data_source: :keep
    ])

    parsed_middleware = extra_args
      |> validate_middleware_string
      |> parse_middleware

    path = Keyword.get(args, :path, "./lib/#{Macro.underscore(args[:app_name])}_web/schema.ex")

    args
      |> AbsintheGeneratorUtils.collect_arguments([:query, :mutation, :subscription, :type, :data_source])
      |> Map.merge(parsed_middleware)
      |> serialize_to_schema_struct
      |> AbsintheGenerator.Schema.run
      |> AbsintheGeneratorUtils.write_template(path)
  end

  defp validate_middleware_string(middleware_args) do
    middleware_string = Enum.join(middleware_args, " ")

    if middleware_string === "" or Regex.match?(@middleware_regex, middleware_string) do
      middleware_args
    else
      Mix.raise("""
      \n
      Middleware format doesn't match what's expected, please make sure it matches the following Regex:

        #{inspect @middleware_regex}

      Example:

        pre_middleware:mutation:MyMiddlewareModule
        pre_middleware:query:MyMiddlewareModule
        pre_middleware:all:MyMiddlewareModule
      """)

    end
  end

  defp parse_middleware(extra_args) do
    middleware_acc = %{
      pre_middleware: [],
      post_middleware: []
    }

    Enum.reduce(extra_args, middleware_acc, fn (arg_string, acc) ->
      [
        middleware_type,
        middleware_query_type,
        middleware_module
      ] = String.split(arg_string, ":")

      middleware_type = String.to_atom(middleware_type)

      middleware = [%{
        type: middleware_query_type,
        module: middleware_module
      }]

      Map.update(acc, middleware_type, middleware, &(&1 ++ middleware))
    end)
  end

  defp serialize_to_schema_struct(params) do
    data_sources = params
      |> Map.get(:data_source, [])
      |> Enum.map(&struct!(AbsintheGenerator.Schema.DataSource, %{source: &1, query: nil}))

    pre_middleware = params
      |> Map.get(:pre_middleware, [])
      |> serialize_middleware

    post_middleware = params
      |> Map.get(:post_middleware, [])
      |> serialize_middleware

    %AbsintheGenerator.Schema{
      app_name: params[:app_name],
      moduledoc: params[:moduledoc],
      queries: params[:query] || [],
      mutations: params[:mutation] || [],
      subscriptions: params[:subscription] || [],
      types: params[:type] || [],
      data_sources: data_sources,
      post_middleware: post_middleware,
      pre_middleware: pre_middleware
    }
  end

  defp serialize_middleware(middleware_params) do
    middleware_params
      |> Enum.group_by(&(&1.module), &(&1.type))
      |> Enum.map(fn {module, types} -> %{types: types, module: module} end)
      |> Enum.map(&struct!(AbsintheGenerator.Schema.Middleware, &1))
  end
end
