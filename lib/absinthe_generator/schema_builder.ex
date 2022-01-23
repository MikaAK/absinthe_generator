defmodule AbsintheGenerator.SchemaBuilder do
  alias AbsintheGenerator.{Type, Resolver, Mutation, Query}

  def generate(app_name, schema_items) do
    {type_items, schema_items} = Enum.split_with(schema_items, &is_struct(&1, Type))
    {mutation_items, schema_items} = Enum.split_with(schema_items, &is_struct(&1, Mutation))
    {query_items, schema_items} = Enum.split_with(schema_items, &is_struct(&1, Query))

    %AbsintheGenerator.Schema{
      app_name: app_name,
      types: Enum.map(type_items, &(&1.type_name)),
      mutations: Enum.map(mutation_items, &(&1.mutation_name)),
      queries: Enum.map(query_items, &(&1.query_name)),
      data_sources: []
    }
  end
end
