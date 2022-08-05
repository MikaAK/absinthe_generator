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
      type: {:list, {:or, [:create, :find, :index, :update, :delete, :find_and_upsert]}}
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

  @type crud_type :: :create | :find | :index | :update | :delete | :find_and_upsert
  @type t :: %AbsintheGenerator.CrudResource{
    app_name: String.t,
    resource_name: String.t,
    moduledoc: String.t,
    resource_fields: list({field_name :: String.t, field_type :: String.t}),
    context_module: module,
    only: list(crud_type),
    except: list(crud_type)
  }

  @mutation_crud_types [:create, :update, :delete, :find_and_upsert]
  @query_crud_types [:find, :index]
  @resource_crud_types @mutation_crud_types ++ @query_crud_types

  def mutation_crud_types, do: @mutation_crud_types
  def query_crud_types, do: @query_crud_types
  def resource_crud_types, do: @resource_crud_types

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
        resolver_functions: resolver_functions(resource_name, context_module, allowed_resources),
      }
    ]

    schema_types = if mutations_enabled?(allowed_resources) do
      app_name
        |> mutation_objects(resource_name, allowed_resources, context_module)
        |> Enum.concat(schema_types)
    else
      schema_types
    end

    if queries_enabled?(allowed_resources) do
      app_name
        |> query_objects(resource_name, allowed_resources, resource_fields_for_non_types, context_module)
        |> Enum.concat(schema_types)
    else
      schema_types
    end
  end

  defp mutation_objects(app_name, resource_name, allowed_resources, context_module) do
    mutation_name = upper_camelize(resource_name)

    mutation = %AbsintheGenerator.Mutation{
      app_name: app_name,
      mutation_name: mutation_name,
      mutations: resource_mutations(resource_name, allowed_resources)
    }

    mutation_test = %AbsintheGenerator.MutationTest{
      app_name: app_name,
      mutation_name: mutation_name,
      mutation_tests: resource_mutation_tests(app_name, resource_name, allowed_resources, context_module)
    }

    [mutation, mutation_test]
  end

  defp query_objects(app_name, resource_name, allowed_resources, resource_fields_for_non_types, context_module) do
    query_name = upper_camelize(resource_name)
    query = %AbsintheGenerator.Query{
      app_name: app_name,
      query_name: query_name,
      queries: resource_queries(resource_name, allowed_resources, resource_fields_for_non_types)
    }

    query_test = %AbsintheGenerator.QueryTest{
      app_name: app_name,
      query_name: query_name,
      query_tests: resource_query_tests(app_name, resource_name, allowed_resources, context_module)
    }

    [query, query_test]
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
        %AbsintheGenerator.Type.Object.Field{} = field -> field

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
        def create(%{#{resource_name}: params}, _resolution) do
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
          {:ok, #{context_module}.all_#{Inflex.pluralize(to_string(resource_name))}(params)}
        end
        """

      :update ->
        """
        def update(%{id: id, #{resource_name}: params}, _resolution) do
          #{context_module}.update_#{resource_name}(id, params)
        end
        """

      :delete ->
        """
        def delete(%{id: id}, _resolution) do
          #{context_module}.delete_#{resource_name}(id)
        end
        """

      :find_and_upsert ->
        """
        def find_and_upsert(%{id: id, #{resource_name}: params} = params, _resolution) do
          #{context_module}.find_and_upsert_#{resource_name}(%{id: id}, Map.delete(params, :id))
        end
        """
    end)
  end

  defp resource_query_tests(app_name, resource_name, allowed_resources, context_module) do
    resource_name_underscored = Macro.underscore(resource_name)
    resource_name = Macro.camelize(resource_name)
    non_capitalized_name = non_capitalized(resource_name)

    allowed_resources
      |> Enum.filter(&(&1 in [:find, :index]))
      |> Enum.map(fn
        :find -> %AbsintheGenerator.TestDescribe{
          describe_name: "@#{resource_name}",
          setup: """
            #{resource_name_underscored} = FactoryEx.insert!(#{factory_name(context_module, resource_name)})

            %{#{resource_name_underscored}: #{resource_name_underscored}}
          """,

          tests: [
            %AbsintheGenerator.TestDescribe.TestEntry{
              description: "finds a #{resource_name} by id",
              params: [resource_name_underscored],
              pre_block: """
              @gql_query """
              query ($id: ID!) {
                #{non_capitalized_name}(id: $id) {
                  id
                }
              }
              \"""
              """,
              function: """
              assert {:ok, %{data: data}} = Absinthe.run(@gql_mutation, #{schema_module(app_name)},
                variables: %{
                  "id" => #{resource_name_underscored}
                }
              )

              assert data["#{non_capitalized_name}"]["id"] === to_string(#{resource_name_underscored}.id)
              """
            }
          ]
        }

        :index ->
          pluralized_non_cap_resource_name = Inflex.pluralize(non_capitalized_name)
          pluralized_resource_name = Inflex.pluralize(non_capitalized_name)

          %AbsintheGenerator.TestDescribe{
            describe_name: "@#{pluralized_non_cap_resource_name}",

            tests: [
              %AbsintheGenerator.TestDescribe.TestEntry{
                description: "finds multiple #{pluralized_resource_name}",
                pre_block: """
                @gql_query """
                query ($ids: ID!) {
                  #{pluralized_non_cap_resource_name}(ids: $ids) {
                    id
                  }
                }
                \"""
                """,
                function: """
                #{resource_name_underscored} = #{Enum.random(3..10)} |> FactoryEx.insert_many!(#{factory_name(context_module, resource_name)}) |> Enum.random

                assert {:ok, %{data: data}} = Absinthe.run(@gql_mutation, #{schema_module(app_name)},
                  variables: %{
                    "ids" => [#{resource_name_underscored}.id]
                  }
                )

                assert hd(data["#{pluralized_non_cap_resource_name}"])["id"] === to_string(#{resource_name_underscored}.id)
                assert id === to_string(#{resource_name_underscored}.id)
                """
              }
            ]
          }
      end)
  end

  defp resource_mutation_tests(app_name, resource_name, allowed_resources, context_module) do
    resource_name_underscored = Macro.underscore(resource_name)
    resource_name = Macro.camelize(resource_name)
    non_capitalized_name = non_capitalized(resource_name)

    allowed_resources
      |> Enum.filter(&(&1 in [:create, :delete, :update]))
      |> Enum.map(fn
        :create -> %AbsintheGenerator.TestDescribe{
          describe_name: "@create#{resource_name}",

          tests: [
            %AbsintheGenerator.TestDescribe.TestEntry{
              description: "creates a schema with valid params",
              pre_block: """
              @gql_query """
              mutation ($#{non_capitalized_name}: #{resource_name}CreateInput) {
                create#{resource_name}(#{non_capitalized_name}: $#{non_capitalized_name}) {
                  id
                }
              }
              \"""
              """,
              function: """
              input_params = FactoryEx.build(#{factory_name(context_module, resource_name)}, [],
                keys: :string,
                key_case: :camel
              )

              assert {:ok, %{data: data}} = Absinthe.run(@gql_mutation, #{schema_module(app_name)},
                variables: %{
                  "#{non_capitalized_name}" => input_params
                }
              )

              assert %{"create#{resource_name}" => %{"id" => id}}
              assert id === to_string(#{resource_name_underscored}.id)
              """
            }
          ]
        }

        :update -> %AbsintheGenerator.TestDescribe{
          describe_name: "@update#{resource_name}",
          setup: """
            #{resource_name_underscored} = FactoryEx.insert!(#{factory_name(context_module, resource_name)})

            %{#{resource_name_underscored}: #{resource_name_underscored}}
          """,

          tests: [
            %AbsintheGenerator.TestDescribe.TestEntry{
              description: "udpates a schema with valid params",
              params: [resource_name_underscored],
              pre_block: """
              @gql_query """
              mutation ($#{non_capitalized_name}: #{resource_name}UpdateInput) {
                update#{resource_name}(#{non_capitalized_name}: $#{non_capitalized_name}) {
                  id
                }
              }
              \"""
              """,
              function: """
              update_params = FactoryEx.build(#{factory_name(context_module, resource_name)}, [], keys: :string, key_case: :camel)

              assert {:ok, %{data: data}} = Absinthe.run(@gql_mutation, #{schema_module(app_name)},
                variables: %{
                  "#{non_capitalized_name}" => update_params
                }
              )

              assert data["#{non_capitalized_name}"]["id"] === to_string(#{resource_name_underscored}.id)

              actual_value = #{factory_name(context_module, resource_name)}.get(#{resource_name_underscored}.id)

              assert Map.take(actual_value, Map.keys(update_params)) === update_params
              """
            }
          ]
        }

        :delete -> %AbsintheGenerator.TestDescribe{
          describe_name: "@delete#{resource_name}",

          tests: [
            %AbsintheGenerator.TestDescribe.TestEntry{
              description: "deletes a #{resource_name}",
              params: [resource_name_underscored],
              pre_block: """
              @gql_query """
              mutation {
                create#{resource_name}(#{resource_name_underscored}) {
                  id
                }
              }
              \"""
              """,
              function: """
                assert {:ok, %{data: data}} = Absinthe.run(@gql_mutation, #{schema_module(app_name)})
              """
            }
          ]
        }
      end)
  end

  defp factory_name(context_module, resource_module) do
    context_parts = context_module |> String.split(".")
    context_module = List.last(context_parts)
    context_parts = context_parts |> Enum.take(length(context_parts) - 1) |> Enum.join(".")

    "#{context_parts}.Factory.#{context_module}.#{resource_module}"
  end

  defp resource_mutations(resource_name, allowed_resources) do
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

      :find_and_upsert, acc ->
        acc ++ [%AbsintheGenerator.Schema.Field{
          name: "find_and_upsert_#{resource_name}",
          return_type: ":#{resource_name}",
          resolver_module_function: "&Resolvers.#{upper_camelize(resource_name)}.find_and_upsert/2",
          arguments: [non_null_id_argument, input_type_argument]
        }]

      _, acc -> acc
    end)
  end

  defp input_type_name(resource_name) do
    "#{resource_name}_input"
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
      {field_name, field_type} ->
        # This doesn't work, because of that this should be re-written into phoenix_config
        Inflex.singularize(field_type) =~ Inflex.singularize(field_name)
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

  defp upper_camelize(<<c::utf8, rest::binary>>), do: Macro.camelize(String.capitalize(<<c>>) <> rest)

  defp non_capitalized(<<c::utf8, rest::binary>>), do: String.downcase(<<c>>) <> rest

  defp schema_module(app_name) do
    "#{Macro.camelize(app_name)}.Schema"
  end
end
