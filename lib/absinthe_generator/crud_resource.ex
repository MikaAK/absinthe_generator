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
      type: {:list, {:or, [:create, :find, :index, :update, :delete]}}
    ],

    except: [
      type: {:list, {:or, [:create, :find, :index, :update, :delete]}}
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

  @type crud_type :: :create | :find | :index | :update | :delete
  @type t :: %AbsintheGenerator.CrudResource{
    app_name: String.t,
    resource_name: String.t,
    moduledoc: String.t,
    resource_fields: list({field_name :: String.t, field_type :: String.t}),
    context_module: module,
    only: list(crud_type),
    except: list(crud_type)
  }

  @resource_crud_types [:create, :find, :index, :update, :delete]

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
    schema_items = [
      %AbsintheGenerator.Type{
        app_name: app_name,
        type_name: resource_name,
        objects: type_objects(resource_name, resource_fields)
      },

      %AbsintheGenerator.Resolver{
        app_name: app_name,
        resolver_name: upper_camelize(resource_name),
        resolver_functions: resolver_functions(resource_fields, context_module, allowed_resources)
      },

      %AbsintheGenerator.Mutation{
        app_name: app_name,
        mutation_name: upper_camelize(resource_name),
        mutations: resource_mutations(resource_name, allowed_resources, resource_fields)
      },

      %AbsintheGenerator.Query{
        app_name: app_name,
        query_name: upper_camelize(resource_name),
        queries: resource_queries(resource_name, allowed_resources, resource_fields)
      }
    ]

    schema_items ++ [AbsintheGenerator.SchemaBuilder.generate(app_name, schema_items)]
  end

  defp type_objects(resource_name, resource_fields) do
    [
      %AbsintheGenerator.Type.Object{
        name: resource_name,
        fields: Enum.map(resource_fields, fn {field_name, field_type} ->
          %AbsintheGenerator.Type.Object.Field{name: field_name, type: field_type}
        end)
      }
    ]
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
    end)
  end

  defp resource_mutations(resource_name, allowed_resources, resource_fields) do
    Enum.reduce(allowed_resources, [], fn
      :update, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "update_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.update/2",
          arguments: Enum.map(resource_fields, fn {field_name, field_type} ->
            %AbsintheGenerator.Schema.Field.Argument{
              name: field_name,
              type: field_type
            }
          end)
        }]

      :delete, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "delete_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.delete/2",
          arguments: [%AbsintheGenerator.Schema.Field.Argument{name: "id", type: ":id"}]
        }]

      :create, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "create_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.create/2",
          arguments: Enum.map(resource_fields, fn {field_name, field_type} ->
            %AbsintheGenerator.Schema.Field.Argument{
              name: field_name,
              type: field_type
            }
          end)
        }]

      _, acc -> acc
    end)
  end

  defp resource_queries(resource_name, allowed_resources, resource_fields) do
    Enum.reduce(allowed_resources, [], fn
      :find, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "find_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.find/2",
          arguments: Enum.map(resource_fields, fn {field_name, field_type} ->
            %AbsintheGenerator.Schema.Field.Argument{
              name: field_name,
              type: field_type
            }
          end)
        }]

      :all, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "all_#{Inflex.pluralize(resource_name)}",
          return_type: "list_of(non_null(:#{resource_name}))",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.all/2",
          arguments: Enum.map(resource_fields, fn {field_name, field_type} ->
            %AbsintheGenerator.Schema.Field.Argument{
              name: field_name,
              type: field_type
            }
          end)
        }]

      _, acc -> acc
    end)
  end

  defp upper_camelize(string), do: string |> String.capitalize |> Macro.camelize
end
