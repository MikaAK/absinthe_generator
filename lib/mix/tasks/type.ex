defmodule Mix.Tasks.Absinthe.Gen.Type do
  use Mix.Task

  alias Mix.AbsintheGeneratorUtils

  @shortdoc "Generates an absinthe type"

  @moduledoc """
  Generates an Absinthe Type

  ### Options

  #{NimbleOptions.docs(AbsintheGenerator.Type.definitions())}

  ### Specifying Types
  To specify types we can utilize the following syntax

  ```bash
  type_name:enum:VALUE_1:VALUE_2:VALUE_3
  type_name:object:name:string:birthday:date:names:list_of(string)
  ```


  ### Example

  ```bash
  mix absinthe.gen.type
    animal:enum:CAT:DOG
    user:object:name:string:birthday:date:id:id:animal:animal
    --app-name MyApp
    --type-name people
  ```
  """

  @enum_regex ~r/enum:([A-Z]+(?!:)|([A-Z]+:[A-Z]+(?!:))+)/
  @object_regex ~r/object:([a-z]+:[a-z]+(?!:))+$/

  @object_or_enum_regex ~r/[a-z]+:(enum:([A-Z]+(?!:)|([A-Z]+:[A-Z]+(?!:))+)|object:([a-z]+:[a-z]+(?!:))+$)/

  def run(args) do
    AbsintheGeneratorUtils.ensure_not_in_umbrella!("absinthe.gen.type")

    {args, extra_args} = AbsintheGeneratorUtils.parse_path_opts(args, [
      path: :string,
      app_name: :string,
      moduledoc: :string,
      type_name: :string
    ])

    parsed_objects_and_enums = extra_args
      |> validate_types_string
      |> parse_object_and_enum_types

    path = Keyword.get(
      args,
      :path,
      "./lib/#{Macro.underscore(args[:app_name])}_web/types/#{Macro.underscore(args[:type_name])}.ex"
    )

    args
      |> Map.new
      |> Map.merge(parsed_objects_and_enums)
      |> serialize_to_type_struct
      |> AbsintheGenerator.Type.run
      |> AbsintheGeneratorUtils.write_template(path)
  end

  defp validate_types_string(type_parts) do
    if type_parts === [] or Enum.all?(type_parts, &Regex.match?(@object_or_enum_regex, &1)) do
      type_parts
    else
      Mix.raise("""
      \n
      Object and Enum format don't match what's expected

      Enums must be formatted according to the following regex

        #{inspect @enum_regex}

      Objects must be formatted according to the following regex

        #{inspect @object_regex}

      Example:

        my_type_name:enum:OPTION_A:OPTION_B
        my_type_name:object:user_name:string:age:integer
      """)
    end
  end

  defp parse_object_and_enum_types(type_parts) do
    Enum.reduce(type_parts, %{enums: [], objects: []}, fn (type_part, acc_params) ->
      if type_part =~ "enum" do
        [type_name, "enum" | types] = String.split(type_part, ":")

        new_value = %AbsintheGenerator.Type.EnumValue{
          name: type_name,
          values: types
        }

        Map.update!(acc_params, :enums, &(&1 ++ [new_value]))
      else
        [type_name, "object" | types] = String.split(type_part, ":")

        new_value = %AbsintheGenerator.Type.Object{
          name: type_name,
          fields: types
            |> Enum.chunk_every(2)
            |> Enum.map(fn [name, type] ->
              %AbsintheGenerator.Type.Object.Field{name: name, type: ":#{type}"}
            end)
        }

        Map.update!(acc_params, :objects, &(&1 ++ [new_value]))
      end
    end)
  end

  defp serialize_to_type_struct(params) do
    %AbsintheGenerator.Type{
      app_name: params[:app_name],
      moduledoc: params[:moduledoc],
      type_name: params[:type_name],
      enums: params[:enums],
      objects: params[:objects]
    }
  end
end
