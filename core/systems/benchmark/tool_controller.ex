defmodule Systems.Benchmark.ToolController do
  use CoreWeb, :controller

  alias Systems.{
    Benchmark
  }

  def ensure_spot(%{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    id = String.to_integer(id)

    spot =
      if spot = List.first(Benchmark.Public.list_owned_spots(id, user)) do
        spot
      else
        Benchmark.Public.create_spot!(id, user)
      end

    path = ~p"/benchmark/#{id}/#{spot.id}"

    conn
    |> redirect(to: path)
  end
end
