defmodule AbsintheGenerator.CrudResource do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    resource_name: Definitions.query_namespace(),
    moduledoc: Definitions.moduledoc(),

    context_module: [
      type: :any,
      required: true,
      description: "Context module for CRUD actions"
    ],

    resource_fields: [
      type: {:list, :string},
      required: true,
      description: "List of fields for thh schema"
    ],

    only: [
      type: {:list, {:or, [
        :create,
        :find,
        :index,
        :update,
        :delete
      ]}}
    ],

    except: [
      type: {:list, {:or, [:create, :find, :index, :update, :delete, :find_and_update_or_create]}}
    ]
  ]

  @moduledoc """
  We can utilize this module to generate crud resource files as well as add
  them into the schema.ex

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @behaviour AbsintheGenerator

  @enforce_keys [:app_name, :resource_name, :context_module]
  defstruct @enforce_keys ++ [
    :moduledoc,
    resource_fields: [],
    only: [],
    except: []
  ]

  @type crud_type :: :create | :find | :index | :update | :delete | :find_and_update_or_create
  @type t :: %AbsintheGenerator.CrudResource{
    app_name: String.t,
    resource_name: String.t,
    moduledoc: String.t,
    resource_fields: list({field_name :: String.t, field_type :: String.t}),
    context_module: module,
    only: list(crud_type),
    except: list(crud_type)
  }

  @mutation_crud_types [:create, :update, :delete, :find_and_update_or_create]
  @query_crud_types [:find, :index ]
  @resource_crud_types @mutation_crud_types ++ @query_crud_types

  @impl AbsintheGenerator
  def run(%AbsintheGenerator.CrudResource{} = crud_resource_struct) do
    if Enum.any?(crud_resource_struct.only) and Enum.any?(crud_resource_struct.except) do
      throw "Must only suply only or except but not both to CrudResource"
    end

    allowed_resources = allowed_resources(crud_resource_struct)

    if Enum.empty?(allowed_resources) do
      throw "At least one resource type must be allowed for CrudResource\nCurrently Allowed: #{inspect allowed_resources}"
    end

    crud_resource_struct
      |> create_resource_structs(allowed_resources)
      |> Enum.map(fn %schema{} = schema_data -> {schema_data, schema.run(schema_data)} end)
  end

  defp allowed_resources(%AbsintheGenerator.CrudResource{
    only: only,
    except: except
  }) do
    if Enum.any?(only) do
      only
    else
      @resource_crud_types -- except
    end
  end

  defp create_resource_structs(%AbsintheGenerator.CrudResource{
    app_name: app_name,
    context_module: context_module,
    resource_name: resource_name,
    resource_fields: resource_fields
  }, allowed_resources) do
    resource_fields_for_non_types = remove_resolver_fields(resource_fields)

    schema_types = [
      %AbsintheGenerator.Type{
        app_name: app_name,
        type_name: resource_name,
        objects: type_objects(resource_name, resource_fields, allowed_resources)
      },

      %AbsintheGenerator.Resolver{
        app_name: app_name,
        resolver_name: upper_camelize(resource_name),
        resolver_functions: resolver_functions(resource_name, context_module, allowed_resources)
      }
    ]

    schema_types = if mutations_enabled?(allowed_resources) do
      [%AbsintheGenerator.Mutation{
        app_name: app_name,
        mutation_name: upper_camelize(resource_name),
        mutations: resource_mutations(resource_name, allowed_resources, resource_fields_for_non_types)
      } | schema_types]
    else
      schema_types
    end

    if queries_enabled?(allowed_resources) do
      [%AbsintheGenerator.Query{
        app_name: app_name,
        query_name: upper_camelize(resource_name),
        queries: resource_queries(resource_name, allowed_resources, resource_fields_for_non_types)
      } | schema_types]
    else
      schema_types
    end
  end

  defp type_objects(resource_name, resource_fields, allowed_resources) do
    if mutations_enabled?(allowed_resources) do
      [type_object(resource_name, resource_fields), input_type_object(resource_name, resource_fields)]
    else
      [type_object(resource_name, resource_fields)]
    end
  end

  defp queries_enabled?(allowed_resources) do
    Enum.any?(allowed_resources, &(&1 in @query_crud_types))
  end

  defp mutations_enabled?(allowed_resources) do
    Enum.any?(allowed_resources, &(&1 in @mutation_crud_types))
  end

  def type_object(resource_name, resource_fields) do
    %AbsintheGenerator.Type.Object{
      name: resource_name,
      fields: Enum.map(resource_fields, fn
        {field_name, field_type} ->
          %AbsintheGenerator.Type.Object.Field{name: field_name, type: field_type}

        {field_name, field_type, resolver} ->
          %AbsintheGenerator.Type.Object.Field{name: field_name, type: field_type, resolver: resolver}
      end)
    }
  end

  def input_type_object(resource_name, resource_fields) do
    resource_fields
      |> remove_resolver_fields
      |> filter_id_name_arguments
      |> filter_relational_types
      |> filter_timestamp_arguments
      |> then(&%{type_object(input_type_name(resource_name), &1) | input?: true})
  end

  defp resolver_functions(resource_name, context_module, allowed_resources) do
    resource_name = Macro.underscore(resource_name)

    Enum.map(allowed_resources, fn
      :create ->
        """
        def create(params, _resolution) do
          #{context_module}.create_#{resource_name}(params)
        end
        """

      :find ->
        """
        def find(params, _resolution) do
          #{context_module}.find_#{resource_name}(params)
        end
        """

      :index ->
        """
        def all(params, _resolution) do
          #{context_module}.all_#{resource_name}(params)
        end
        """

      :update ->
        """
        def update(%{id: id} = params, _resolution) do
          #{context_module}.update_#{resource_name}(id, params)
        end
        """

      :delete ->
        """
        def delete(%{id: id}, _resolution) do
          #{context_module}.delete_#{resource_name}(id)
        end
        """

      :find_and_update_or_create ->
        """
        def find_and_update_or_create(%{id: id} = params, _resolution) do
          #{context_module}.find_and_update_or_create_#{resource_name}(id, Map.delete(params, :id))
        end
        """
    end)
  end

  defp resource_mutations(resource_name, allowed_resources, resource_fields) do
    non_null_id_argument = %AbsintheGenerator.Schema.Field.Argument{name: "id", type: "non_null(:id)"}
    input_type_argument = %AbsintheGenerator.Schema.Field.Argument{name: resource_name, type: "non_null(:#{input_type_name(resource_name)})"}


    Enum.reduce(allowed_resources, [], fn
      :update, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "update_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.update/2",
          arguments: [non_null_id_argument, input_type_argument]
        }]

      :delete, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "delete_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.delete/2",
          arguments: [non_null_id_argument]
        }]

      :create, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "create_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.create/2",
          arguments: [input_type_argument]
        }]

      :find_and_update_or_create, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "find_and_update_or_create_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.find_and_update_or_create/2",
          arguments: [non_null_id_argument, input_type_argument]
        }]

      _, acc -> acc
    end)
  end

  defp input_type_name(resource_name) do
    "#{resource_name}_input"
  end

  defp filter_id_arguments(resource_fields) do
    Stream.reject(resource_fields, fn {_, field_type} ->
      field_type === ":id"
    end)
  end

  defp remove_resolver_fields(resource_fields) do
    Stream.map(resource_fields, fn
      {_, _} = resource -> resource
      {field_name, field_type, _resolver} -> {field_name, field_type}
    end)
  end

  defp resource_queries(resource_name, allowed_resources, resource_fields) do
    Enum.reduce(allowed_resources, [], fn
      :find, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.find/2",
          arguments: resource_fields
            |> filter_relational_types
            |> filter_datetime_arguments
            |> Enum.map(fn {field_name, field_type} ->
              %AbsintheGenerator.Schema.Field.Argument{
                name: field_name,
                type: field_type
              }
            end)
        }]

      :index, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "#{Inflex.pluralize(resource_name)}",
          return_type: "list_of(non_null(:#{resource_name}))",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.all/2",
          arguments: resource_fields
            |> filter_relational_types
            |> filter_datetime_arguments
            |> filter_id_name_arguments
            |> Enum.map(fn {field_name, field_type} ->
              %AbsintheGenerator.Schema.Field.Argument{
                name: field_name,
                type: field_type
              }
            end)
        }]

      _, acc -> acc
    end)
  end

  defp filter_relational_types(resource_fields) do
    Stream.reject(resource_fields, fn
      {"id", _} -> false
      {field_name, field_type} -> Inflex.singularize(field_type) =~ Inflex.singularize(field_name)
    end)
  end

  defp filter_datetime_arguments(resource_fields) do
    Stream.reject(resource_fields, fn {_, field_type} ->
      field_type === ":datetime"
    end)
  end

  defp filter_id_name_arguments(resource_fields) do
    Stream.reject(resource_fields, fn {field_name, _} ->
      field_name === "id"
    end)
  end

  defp filter_timestamp_arguments(resource_fields) do
    Stream.reject(resource_fields, fn {field_name, _} ->
      field_name in ["inserted_at", "updated_at"]
    end)
  end

  defp upper_camelize(string), do: string |> String.capitalize |> Macro.camelize
end
