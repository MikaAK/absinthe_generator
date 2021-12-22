defmodule Mix.Tasks.Absinthe.Gen.Query do
  @shortdoc "Generates an absinthe query schema and inserts the record in the base schema.ex"

  @moduledoc """
  Generates an Absinthe Query

  ### Options

  #{NimbleOptions.docs(AbsintheGenerator.Query.definitions())}

  ### Specifying Queries
  The following format can be used to specify queries

  ```bash
  query_name:return_type:arg_name:arg_type:arg_name:arg_type:ResolverModule.resolver_function
  ```

  you can also specify middleware before or after the resolver

  ### Example

  ```bash
  mix absinthe.gen.query
    summoners:list_of(return_type):arg_a:string:arg_b:non_null(:integer):Resolvers.Summoner.list_all
    summoner:return_type:id:id:Resolvers.Summoner.find
    summoner:return_type:middleware:IDToIntegerMiddlewareid:id:middleware:AuthMiddleware:Resolvers.Summoner.find:middleware:ChangesetErrorFormatter
    --app-name MyApp
    --query-name students
    --moduledoc "this is the test"
  ```
  """

  use Mix.Task

  alias Mix.AbsintheGeneratorUtils
  alias Mix.AbsintheGeneratorUtils.SchemaFieldParser

  @query_regex ~r/^$/

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.query")

    {args, extra_args} = AbsintheGeneratorUtils.parse_path_opts(args, [
      path: :string,
      app_name: :string,
      moduledoc: :string,
      query_name: :string
    ])

    parsed_query_functions = extra_args
      |> validate_query_string
      |> SchemaFieldParser.parse_fields

    args
      |> Map.new
      |> Map.put(:queries, parsed_query_functions)
      |> serialize_to_query_struct
      |> IO.inspect
      |> AbsintheGenerator.Query.run
      |> AbsintheGeneratorUtils.write_template(path_from_args(args))
  end

  defp path_from_args(args) do
    Keyword.get(
      args,
      :path,
      "./lib/#{Macro.underscore(args[:app_name])}_web/queries/#{Macro.underscore(args[:query_name])}.ex"
    )
  end

  defp validate_query_string(query_parts) do
    if query_parts === [] or Enum.all?(query_parts, &Regex.match?(@query_regex, &1)) do
      query_parts
    else
      Mix.raise("""
      \n
      Query format isn't setup properly and must match the following regex

        #{inspect @query_regex}

      Example:

        summoners:list_of(return_type):arg_a:string:arg_b:non_null(:integer):Resolvers.Summoner.list_all
        summoner:return_type:id:id:Resolvers.Summoner.find
        summoner:return_type:middleware:IDToIntegerMiddlewareid:id:middleware:AuthMiddleware:Resolvers.Summoner.find:middleware:ChangesetErrorFormatter
      """)
    end
  end

  defp serialize_to_query_struct(params) do
    %AbsintheGenerator.Query{
      app_name: params[:app_name],
      moduledoc: params[:moduledoc],
      query_name: params[:query_name],
      queries: params[:queries]
    }
  end
end
