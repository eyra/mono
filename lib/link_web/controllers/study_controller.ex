defmodule LinkWeb.StudyController do
  use LinkWeb, :controller

  alias Link.Studies
  alias Link.Studies.Study

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

  def show(conn, %{"id" => id}) do
    study = Studies.get_study!(id)
    render(conn, "show.html", study: study)
  end

  def edit(conn, %{"id" => id}) do
    study = Studies.get_study!(id)
    changeset = Studies.change_study(study)
    render(conn, "edit.html", study: study, changeset: changeset)
  end

  def update(conn, %{"id" => id, "study" => study_params}) do
    study = Studies.get_study!(id)

    case Studies.update_study(study, study_params) do
      {:ok, study} ->
        conn
        |> put_flash(:info, "Study updated successfully.")
        |> redirect(to: Routes.study_path(conn, :show, study))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", study: study, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    study = Studies.get_study!(id)
    {:ok, _study} = Studies.delete_study(study)

    conn
    |> put_flash(:info, "Study deleted successfully.")
    |> redirect(to: Routes.study_path(conn, :index))
  end
end
