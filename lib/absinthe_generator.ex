defmodule AbsintheGenerator do
  @moduledoc File.read!("./README.md")

  @locals_without_parens [
    import_types: 1,
    import_fields: 1,
    arg: 2,
    field: 2,
    middleware: 1,
    middleware: 2,
    resolve: 1
  ]

  def moduledoc, do: @moduledoc

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def template_path(template_name) do
    Path.join(:code.priv_dir(:absinthe_generator), "templates/#{template_name}.ex.eex")
  end

  def evaluate_template(template_path, assigns) do
    template_path
      |> EEx.eval_file(assigns)
      |> Code.format_string!(locals_without_parens: @locals_without_parens)
  end
end
