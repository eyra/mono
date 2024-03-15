defmodule Systems.Benchmark.ToolController do
  use CoreWeb, :controller

  def ensure_spot(%{assigns: %{current_user: _user}} = conn, %{"id" => _id}) do
    # TODO: PreRef

    # id = String.to_integer(id)

    # spot =
    #   if spot = List.first(Benchmark.Public.list_spots_for_tool(user, id)) do
    #     spot
    #   else
    #     Benchmark.Public.create_spot!(id, user)
    #   end

    # path = ~p"/benchmark/#{id}/#{spot.id}"

    # conn
    # |> redirect(to: path)

    conn
  end
end
