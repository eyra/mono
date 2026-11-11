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
      {:ok, entries} -> Enum.any?(entries, &match?({:zip_file, ~c"index.html", _, _, _, _}, &1))
      _ -> false
    end
  end
end
