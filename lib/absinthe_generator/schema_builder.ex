defmodule AbsintheGenerator.SchemaBuilder do
  alias AbsintheGenerator.{Type, Resolver, Mutation, Query, Schema}

  @dataloader_regex ~r/^dataloader\(([^,]+)/

  def generate(app_name, schema_items) do
    {type_items, schema_items} = Enum.split_with(schema_items, &is_struct(&1, Type))
    {mutation_items, schema_items} = Enum.split_with(schema_items, &is_struct(&1, Mutation))
    query_items = Enum.filter(schema_items, &is_struct(&1, Query))

    %Schema{
      app_name: app_name,
      types: Enum.map(type_items, &("Types.#{Macro.camelize(&1.type_name)}")),
      mutations: Enum.map(mutation_items, &(&1.mutation_name)),
      queries: Enum.map(query_items, &(&1.query_name)),
      data_sources: extract_data_sources(type_items)
    }
  end

  defp extract_data_sources(type_items) do
    type_items
      |> Stream.flat_map(&filter_fields_with_dataloader/1)
      |> Stream.map(&dataloader_source_module/1)
      |> Stream.uniq()
      |> Enum.map(&build_data_source_struct/1)
  end

  defp filter_fields_with_dataloader(%Type{objects: objects}) do
    objects
      |> Stream.flat_map(&(&1.fields))
      |> Enum.filter(&(not is_nil(&1.resolver) and &1.resolver =~ "dataloader"))
  end

  defp dataloader_source_module(%Type.Object.Field{resolver: resolver_string}) do
    case Regex.run(@dataloader_regex, resolver_string, [capture: :all_but_first]) do
      [data_source] -> data_source
      _ -> raise "Data source could not be found from #{inspect resolver_string}"
    end
  end

  defp build_data_source_struct(data_source) do
    %Schema.DataSource{
      source: data_source,
      query: """
        Dataloader.Ecto.new(
          BlitzPG.Repo.Apex,
          query: &EctoShorts.CommonFilters.convert_params_to_filter/2
        )
      """
    }
  end
end
