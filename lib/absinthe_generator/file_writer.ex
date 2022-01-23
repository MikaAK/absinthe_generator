defmodule AbsintheGenerator.FileWriter do
  @callback file_path(generation_struct :: struct) :: Path.t | String.t

  def write(%generation_struct{} = data, file_contents) do
    file_path = generation_struct.file_path(data)

    if File.exists?(file_path) do
      inject_contents_to_existing_file(file_path, file_contents)
    else
      force_write_file(file_path, file_contents)
    end
  end

  defp force_write_file(path, contents) do
    File.mkdir_p!(Path.dirname(path))

    File.write!(path, contents)
  end

  def inject_contents_to_existing_file(path, contents) do

  end
end
