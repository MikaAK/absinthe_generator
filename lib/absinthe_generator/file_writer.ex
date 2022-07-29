defmodule AbsintheGenerator.FileWriter do
  @moduledoc """
  Implements a behaviour that each absinthe generator struct implements which enables
  this module to write contents to the file path defined by the structs callback

  Additionally it will determine if there's a web folder and if we need to use that instead
  """

  @callback file_path(generation_struct :: struct) :: Path.t | String.t

  def write(%generation_struct{app_name: app_name} = data, file_contents, opts) do
    data
      |> generation_struct.file_path()
      |> maybe_use_web_folder(app_name)
      |> Mix.Generator.create_file(file_contents, opts)
  end

  defp maybe_use_web_folder(file_path, app_name) do
    path = "./lib/#{Macro.underscore(app_name)}"
    web_path = "#{path}_web"

    if File.dir?(web_path) do
      String.replace(file_path, path, web_path)
    else
      file_path
    end
  end
end
