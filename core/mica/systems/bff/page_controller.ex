defmodule Systems.BFF.PageController do
  use MicaWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.BFF

  @doc """
  The view model of `page` as `%{"blocks" => [...], "markup" => [...]}`, for the page's
  params in the query (`Systems.BFF.Blocks.view_model/2`, which raises on bad markup).
  401 when signed out, before the page is looked up; 404 for a page the spec doesn't
  list or no system serves.
  """
  def show(conn, %{"page" => page}) do
    Logger.metadata(bff_spec: conn |> get_req_header("x-bff-spec") |> List.first())

    case {conn.assigns[:current_user], page(page)} do
      {nil, _} ->
        conn |> put_status(:unauthorized) |> json(%{error: "Not authenticated"})

      {_user, nil} ->
        conn |> put_status(:not_found) |> json(%{error: "Not found"})

      {user, {name, module}} ->
        params = BFF.Blocks.page_params(name, conn.query_params)
        {blocks, markup} = module.view_model(user, params)
        json(conn, BFF.Blocks.view_model(blocks, markup))
    end
  end

  defp page(name) do
    with %{name: page} <- Enum.find(BFF.Blocks.pages(), &(Atom.to_string(&1.name) == name)),
         module when module != nil <- Map.get(Mica.SaaS.bff_pages(), page) do
      {page, module}
    end
  end
end
