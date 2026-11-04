defmodule Systems.BFF.PageController do
  use MicaWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.BFF

  @doc """
  The blocks of `page` as `%{"blocks" => [...]}`. 401 when signed out, before the
  page is looked up; 404 for a page the spec doesn't list or no system serves.
  """
  def show(conn, %{"page" => page}) do
    Logger.metadata(bff_spec: conn |> get_req_header("x-bff-spec") |> List.first())

    case {conn.assigns[:current_user], page_module(page)} do
      {nil, _} ->
        conn |> put_status(:unauthorized) |> json(%{error: "Not authenticated"})

      {_user, nil} ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      {user, module} ->
        json(conn, %{blocks: Enum.map(module.blocks(user), &to_map/1)})
    end
  end

  defp page_module(name) do
    with %{name: page} <- Enum.find(BFF.Blocks.pages(), &(Atom.to_string(&1.name) == name)) do
      Map.get(Mica.SaaS.bff_pages(), page)
    end
  end

  defp to_map(%module{} = block), do: module.to_map(block)
end
