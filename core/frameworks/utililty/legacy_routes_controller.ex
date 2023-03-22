defmodule Frameworks.Utility.LegacyRoutesController do
  use CoreWeb, :controller

  alias Core.Accounts

  alias Systems.{
    Campaign,
    Assignment
  }

  # task/:type/:id/callback -> assignment/:id/callback
  def task_callback(%{assigns: %{current_user: user}} = conn, %{"type" => "campaign", "id" => id}) do
    %{promotable_assignment: %{crew: crew}} =
      Campaign.Public.get!(id, promotable_assignment: [:crew])

    case crew do
      nil ->
        redirect_to_live(conn, Accounts.start_page_target(user))

      crew ->
        # expect one assignment here
        assignments = Assignment.Public.get_by_crew!(crew)
        redirect_to_live(conn, Systems.Assignment.CallbackPage, assignments)
    end
  end

  defp redirect_to_live(conn, action), do: redirect_to(conn, Routes.live_path(conn, action))
  defp redirect_to_live(conn, action, [model | _]), do: redirect_to_live(conn, action, model)
  defp redirect_to_live(conn, action, %{id: id}), do: redirect_to_live(conn, action, id)

  defp redirect_to_live(conn, action, id),
    do: redirect_to(conn, Routes.live_path(conn, action, id))

  defp redirect_to(conn, path) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: path)
  end
end
