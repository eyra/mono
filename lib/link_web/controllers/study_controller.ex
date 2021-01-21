defmodule LinkWeb.StudyController do
  use LinkWeb, :controller

  alias Link.Users
  alias Link.Studies
  alias Link.Studies.Study

  entity_loader(&LinkWeb.Loaders.study!/3)

  def index(conn, _params) do
    studies = Studies.list_studies()
    render(conn, "index.html", studies: studies)
  end

  def new(conn, _params) do
    changeset = Studies.change_study(%Study{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"study" => study_params}) do
    researcher = Pow.Plug.current_user(conn)

    case Studies.create_study(study_params, researcher) do
      {:ok, study} ->
        conn
        |> put_flash(:info, "Study created successfully.")
        |> redirect(to: Routes.study_path(conn, :show, study))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(%{assigns: %{study: study}} = conn, _) do
    user = Pow.Plug.current_user(conn)

    owner_profile =
      study
      |> Studies.list_owners()
      |> Enum.at(0)
      |> Users.get_profile()

    participants =
      study
      |> Studies.list_participants()
      |> Enum.map(fn %{user_id: user_id} -> Users.get_display_label(user_id) end)

    application_status = Studies.application_status(study, user)
    can_participate = application_status === nil

    render(conn, "show.html",
      study: study,
      participants: participants,
      can_participate: can_participate,
      owner_profile: owner_profile
    )
  end

  def edit(%{assigns: %{study: study}} = conn, _) do
    changeset = Studies.change_study(study)
    render(conn, "edit.html", study: study, changeset: changeset)
  end

  def update(%{assigns: %{study: study}} = conn, %{"study" => study_params}) do
    case Studies.update_study(study, study_params) do
      {:ok, study} ->
        conn
        |> put_flash(:info, "Study updated successfully.")
        |> redirect(to: Routes.study_path(conn, :show, study))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", study: study, changeset: changeset)
    end
  end

  def delete(%{assigns: %{study: study}} = conn, _) do
    {:ok, _study} = Studies.delete_study(study)

    conn
    |> put_flash(:info, "Study deleted successfully.")
    |> redirect(to: Routes.static_path(conn, "/dashboard"))
  end
end
