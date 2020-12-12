defmodule LinkWeb.ParticipantController do
  use LinkWeb, :controller

  alias Link.Studies
  alias Link.Studies.Participant
  entity_loader(&LinkWeb.Loaders.study!/3)

  # def index(conn, _params) do
  #   participants = Studies.list_participants()
  #   render(conn, "index.html", participants: participants)
  # end

  def new(%{assigns: %{study: study}} = conn, _params) do
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

  # def show(conn, %{"id" => id}) do
  #   participant = Studies.get_participant!(id)
  #   render(conn, "show.html", participant: participant)
  # end

  # def edit(conn, %{"id" => id}) do
  #   participant = Studies.get_participant!(id)
  #   changeset = Studies.change_participant(participant)
  #   render(conn, "edit.html", participant: participant, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "participant" => participant_params}) do
  #   participant = Studies.get_participant!(id)

  #   case Studies.update_participant(participant, participant_params) do
  #     {:ok, participant} ->
  #       conn
  #       |> put_flash(:info, "Participant updated successfully.")
  #       |> redirect(to: Routes.participant_path(conn, :show, participant))

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", participant: participant, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   participant = Studies.get_participant!(id)
  #   {:ok, _participant} = Studies.delete_participant(participant)

  #   conn
  #   |> put_flash(:info, "Participant deleted successfully.")
  #   |> redirect(to: Routes.participant_path(conn, :index))
  # end
end
