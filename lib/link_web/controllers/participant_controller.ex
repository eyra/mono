defmodule LinkWeb.ParticipantController do
  use LinkWeb, :controller

  alias Link.Users
  alias Link.Studies

  entity_loader(&LinkWeb.Loaders.study!/3)

  def index(%{assigns: %{study: study}} = conn, _params) do
    participants = Studies.list_participants(study)
    render(conn, "index.html", participants: participants)
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(%{assigns: %{study: study}} = conn, _params) do
    case Studies.apply_participant(study, Pow.Plug.current_user(conn)) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "You applied to participate in this study.")
        |> redirect(to: Routes.study_path(conn, :show, study))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def update(%{assigns: %{study: study}} = conn, %{"participation" => participation}) do
    with status <-
           Ecto.Changeset.cast(%Studies.Participant{}, participation, [:status])
           |> Ecto.Changeset.get_change(:status),
         user_id <- Map.get(participation, "user_id"),
         user <- Users.get_by(id: user_id),
         :ok <- Studies.update_participant_status(study, user, status) do
      conn
      |> put_flash(:info, "Participant accepted")
      |> redirect(to: Routes.participant_path(conn, :index, study))
    else
      _ ->
        conn
        |> put_flash(:info, "Error occured")
        |> redirect(to: Routes.participant_path(conn, :index, study))
    end
  end
end
