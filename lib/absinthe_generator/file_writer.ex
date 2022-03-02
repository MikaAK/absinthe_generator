defmodule AbsintheGenerator.FileWriter do
  @callback file_path(generation_struct :: struct) :: Path.t | String.t

  def write(%generation_struct{} = data, file_contents, opts) do
    file_path = generation_struct.file_path(data)

    Mix.Generator.create_file(file_path, file_contents, opts)
  end
end
