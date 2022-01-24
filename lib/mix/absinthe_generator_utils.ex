defmodule Mix.AbsintheGeneratorUtils do
  @moduledoc false

  def parse_path_opts(args, switches \\ []) do
    {opts, extra_args, _} = OptionParser.parse(args,
      switches: Keyword.merge([path: :string], switches)
    )

    {opts, extra_args}
  end

  def ensure_not_in_umbrella!(command) do
    if Mix.Project.umbrella?() do
      Mix.raise("mix #{command} must be invoked from within your *_web application root directory")
    end
  end

  def write_template(contents, file_path) do
    if Mix.Generator.overwrite?(file_path, contents) do
      directory = Path.dirname(file_path)

      if not File.dir?(directory) do
        Mix.Generator.create_directory(directory)
      end

      Mix.Generator.create_file(file_path, contents)
    else
      Mix.raise("Aborted writing template to #{file_path}")
    end
  end

  def collect_arguments(args, fields) do
    collected_args = args
      |> Keyword.take(fields)
      |> Enum.group_by(fn {key, _} -> key end, fn {_, value} -> value end)

    args
      |> Keyword.drop(fields)
      |> Map.new
      |> Map.merge(collected_args)
  end
end
