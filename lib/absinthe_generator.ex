defmodule AbsintheGenerator do
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

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def ensure_list_of_structs(list, struct, field_name) do
    case Enum.find(list, &(not is_struct(&1, struct))) do
      nil -> :ok
      non_struct -> Mix.raise("The list of #{field_name} must be a list of %#{inspect struct}{} but instead found:\n#{inspect non_struct}")
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
        Mix.raise("Error inside the resulting template: \n #{code}")
  end
end
