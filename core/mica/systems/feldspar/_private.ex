defmodule Systems.Feldspar.Private do
  def get_backend do
    Mica.Env.fetch!(:feldspar)
    |> Access.fetch!(:backend)
  end

  @doc """
  Whether the zip holds an `index.html` at its root, the page the task modal loads.
  """
  def index_html?(zip_file) do
    case :zip.list_dir(to_charlist(zip_file)) do
      {:ok, entries} ->
        "index.html" in for({:zip_file, name, _, _, _, _} <- entries, do: entry_path(name))

      _ ->
        false
    end
  end

  @doc """
  The entry's path inside the app. Drops the leading `./` that bsdtar
  (`tar -a -cf app.zip .`) writes before every name.
  """
  def entry_path(name), do: name |> to_string() |> drop_dot_slash()

  defp drop_dot_slash("./" <> path), do: drop_dot_slash(path)
  defp drop_dot_slash(path), do: path
end
