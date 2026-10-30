defmodule Next.Systems.Graphite.ToolController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  def ensure_spot(%{assigns: %{current_user: _user}} = conn, %{"id" => _id}) do
    # FIXME: PreRef

    # id = String.to_integer(id)

    # spot =
    #   if spot = List.first(Graphite.Public.list_spots_for_tool(user, id)) do
    #     spot
    #   else
    #     Graphite.Public.create_spot!(id, user)
    #   end

    # path = ~p"/graphite/#{id}/#{spot.id}"

    # conn
    # |> redirect(to: path)

    conn
  end
end
