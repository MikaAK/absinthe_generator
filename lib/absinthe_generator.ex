defmodule AbsintheGenerator do
  @doc "This callback is for each resource to create it's own struct"
  @callback run(resource_struct :: struct) :: any

  @moduledoc File.read!("./README.md")

  @locals_without_parens [
    import_types: 1,
    import_fields: 1,
    arg: 2,
    field: 2,
    field: 3,
    middleware: 1,
    middleware: 2,
    resolve: 1,
    value: 1,
    value: 2
  ]

  def moduledoc, do: @moduledoc

  def run(%resource_struct{} = struct_data), do: resource_struct.run(struct_data)

  def ensure_list_of_structs(list, struct, field_name) do
    case Enum.find(list, &(not is_struct(&1, struct))) do
      nil -> :ok
      non_struct -> raise "The list of #{field_name} must be a list of %#{inspect struct}{} but instead found:\n#{inspect non_struct}"
    end
  end

  def template_path(template_name) do
    Path.join(:code.priv_dir(:absinthe_generator), "templates/#{template_name}.ex.eex")
  end

  def evaluate_template(template_path, assigns) do
    template_path
      |> EEx.eval_file(assigns)
      |> attempt_to_format_template
  end

  defp attempt_to_format_template(code) do
    Code.format_string!(code, locals_without_parens: @locals_without_parens)

    rescue
      SyntaxError ->
        reraise "Error inside the resulting template: \n #{code}", __STACKTRACE__
  end

  def serialize_struct_to_config(structs) when is_list(structs) do
    Enum.map(structs, &serialize_struct_to_config/1)
  end

  def serialize_struct_to_config(struct) when is_struct(struct) do
    struct
      |> Map.from_struct
      |> serialize_struct_to_config
  end

  def serialize_struct_to_config(struct) when is_map(struct) do
    Enum.reduce(struct, [], fn
      ({_, nil}, acc) -> acc

      ({key, value}, acc) when is_struct(value) or is_list(value) ->
        Keyword.put(acc, key, serialize_struct_to_config(value))

      ({key, value}, acc) when is_map(value) ->
        Keyword.put(acc, key, serialize_struct_to_config(value))

      ({key, value}, acc) -> Keyword.put(acc, key, value)
    end)
  end

  def serialize_struct_to_config(value) do
    value
  end
end
