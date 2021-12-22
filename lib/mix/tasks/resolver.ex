defmodule Mix.Tasks.Absinthe.Gen.Resolver do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe resolver"

  @moduledoc """
  Generates an Absinthe Schema

  ### Options

  #{NimbleOptions.docs(AbsintheGenerator.Resolver.definitions())}

  ### Specifying Middleware
  To specify middleware we can utilize the following syntax

  ```bash
  pre_middleware:mutation:AuthMiddleware post_middleware:all:ChangesetErrorFormatter
  ```

  Middleware can be set for `mutation`, `query`, `subscription` or `all` and can
  also be set to either run pre or post resolution using `pre_middleware` or `post_middleware`


  ### Example

  ```bash
  mix absinthe.gen.resolver func_name:2:MyModule.function
    --app-name MyApp
    --resolver-name students
    --moduledoc "this is the test"
  ```
  """

  @resolver_regex ~r/^[a-z_]+(:(with_parent|with_resolution|with_parent:with_resolution)){0,1}:[A-Za-z]+\.[a-z_]+$/

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.resolver")

    {args, extra_args} = AbsintheGeneratorUtils.parse_path_opts(args, [
      path: :string,
      app_name: :string,
      moduledoc: :string,
      resolver_name: :string
    ])

    parsed_resolver_functions = extra_args
      |> validate_resolver_string
      |> parse_resolver_functions

    args
      |> Map.new
      |> Map.put(:resolver_functions, parsed_resolver_functions)
      |> serialize_to_resolver_struct
      |> AbsintheGenerator.Resolver.run
      |> AbsintheGeneratorUtils.write_template(path_from_args(args))
  end

  defp path_from_args(args) do
    Keyword.get(
      args,
      :path,
      "./lib/#{Macro.underscore(args[:app_name])}_web/resolvers/#{Macro.underscore(args[:resolver_name])}.ex"
    )
  end

  defp validate_resolver_string(resolver_parts) do
    if resolver_parts === [] or Enum.all?(resolver_parts, &Regex.match?(@resolver_regex, &1)) do
      resolver_parts
    else
      Mix.raise("""
      \n
      Resolver format isn't setup properly and must match the following regex

        #{inspect @resolver_regex}

      Example:

        func_name:MyModule.function
        all_users:with_parent:Account.all_users
        all_users:with_resolution:Account.all_users
        all_users:with_parent:with_resolution:Account.all_users
      """)
    end
  end

  defp parse_resolver_functions(parsed_resolver_functions) do
    Enum.map(parsed_resolver_functions, fn resolver_function ->
      case String.split(resolver_function, ":") do
        [resolver_func_name, fn_name] ->
          """
          def #{resolver_func_name}(params, _resolution) do
            #{fn_name}(params)
          end
          """

        [resolver_func_name, "with_parent", "with_resolution", fn_name] ->
          """
          def #{resolver_func_name}(params, parent, resolution) do
            #{fn_name}(params, parent, resolution)
          end
          """

        [resolver_func_name, "with_parent", fn_name] ->
          """
          def #{resolver_func_name}(params, parent) do
            #{fn_name}(params, parent)
          end
          """

        [resolver_func_name, "with_resolution", fn_name] ->
          """
          def #{resolver_func_name}(params, resolution) do
            #{fn_name}(params, resolution)
          end
          """
      end
    end)
  end

  defp serialize_to_resolver_struct(params) do
    %AbsintheGenerator.Resolver{
      app_name: params[:app_name],
      moduledoc: params[:moduledoc],
      resolver_name: params[:resolver_name],
      resolver_functions: params[:resolver_functions]
    }
  end
end

