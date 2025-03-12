defmodule Systems.Manual.Public do
  import Ecto.Changeset

  alias Core.Repo
  alias Systems.Manual
  alias Systems.Userflow

  @doc """
  Creates a new manual with a chapter userflow.
  """
  def create(title, attrs \\ %{}) do
    # Create a userflow for chapters
    with {:ok, userflow} <- Userflow.Public.create() do
      %Manual.Model{}
      |> Manual.Model.changeset(Map.merge(attrs, %{title: title}))
      |> put_assoc(:userflow, userflow)
      |> Repo.insert()
    end
  end

  @doc """
  Gets a manual by its id.
  """
  def get!(id) do
    Manual.Queries.get_by_id(id)
    |> Repo.one!()
  end

  def get_chapter_by_step!(%Userflow.StepModel{id: step_id}) do
    Manual.Queries.get_chapter_by_userflow_step!(step_id)
    |> Repo.one!()
  end

  @doc """
    Adds a chapter to a manual.
  """
  def add_chapter(%Manual.Model{} = manual, group, attrs) do
    add_chapter(%Ecto.Multi{}, manual, group, attrs)
  end

  @doc """
    Adds a chapter to a manual.
  """
  def add_chapter(
        %Ecto.Multi{} = multi,
        %Manual.Model{userflow: manual_userflow} = manual,
        group,
        attrs
      ) do
    multi
    |> Ecto.Multi.run(:userflow_step, fn _, _ ->
      # Create a userflow step for linking the chapter to the manual userflow
      Userflow.Public.add_step(manual_userflow, group)
    end)
    |> Ecto.Multi.run(:userflow, fn _, _ ->
      # Create a new userflow for making the chapter a userflow itself
      Userflow.Public.create()
    end)
    |> Ecto.Multi.insert(:chapter, fn %{userflow_step: userflow_step, userflow: userflow} ->
      %Manual.ChapterModel{}
      |> Manual.ChapterModel.changeset(attrs)
      |> put_assoc(:manual, manual)
      |> put_assoc(:userflow_step, userflow_step)
      |> put_assoc(:userflow, userflow)
    end)
    |> Repo.transaction()
  end

  @doc """
  Gets all chapters in a manual.
  """
  def get_chapters(manual) do
    Manual.Queries.get_chapters(manual.id)
    |> Repo.all()
  end

  def get_page_by_step!(%Userflow.StepModel{id: step_id}) do
    Manual.Queries.get_page_by_userflow_step!(step_id)
    |> Repo.one!()
  end

  @doc """
    Adds a page to a chapter.
  """
  def add_page(%Manual.ChapterModel{} = chapter, group, attrs) do
    add_page(%Ecto.Multi{}, chapter, group, attrs)
  end

  @doc """
    Adds a page to a chapter.
  """
  def add_page(
        %Ecto.Multi{} = multi,
        %Manual.ChapterModel{userflow: chapter_userflow} = chapter,
        group,
        attrs
      ) do
    # Create the userflow step first
    multi
    |> Ecto.Multi.run(:userflow_step, fn _, _ ->
      Userflow.Public.add_step(chapter_userflow, group)
    end)
    |> Ecto.Multi.insert(:page, fn %{userflow_step: userflow_step} ->
      %Manual.PageModel{}
      |> Manual.PageModel.changeset(attrs)
      |> put_assoc(:chapter, chapter)
      |> put_assoc(:userflow_step, userflow_step)
    end)
    |> Repo.transaction()
  end

  @doc """
  Gets the next unvisited chapter for a user in a manual.
  """
  def next_chapter(%Manual.Model{userflow: manual_userflow}, user) do
    case Userflow.Public.next_step(manual_userflow, user.id) do
      nil ->
        nil

      step ->
        get_chapter_by_step!(step)
    end
  end

  @doc """
  Gets the next unvisited step for a user in a chapter.
  """
  def next_page(%Manual.ChapterModel{userflow: chapter_userflow}, user) do
    step = Userflow.Public.next_step(chapter_userflow, user.id)
    get_page_by_step!(step)
  end

  @doc """
  Checks if a user has finished all chapters in a manual.
  """
  def finished_chapters?(%Manual.Model{userflow: manual_userflow}, user_id) do
    Userflow.Public.finished?(manual_userflow, user_id)
  end

  @doc """
  Checks if a user has finished all steps in a chapter.
  """
  def finished_steps?(%Manual.ChapterModel{userflow: chapter_userflow}, user_id) do
    Userflow.Public.finished?(chapter_userflow, user_id)
  end

  @doc """
  Gets all chapters in a manual grouped by their group field.
  """
  def chapters_by_group(%Manual.Model{userflow: manual_userflow}) do
    manual_userflow
    |> Repo.preload(:steps)
    |> Userflow.Public.steps_by_group()
  end

  @doc """
  Gets all pages in a chapter grouped by their group field.
  """
  def pages_by_group(%Manual.ChapterModel{userflow: chapter_userflow}) do
    chapter_userflow
    |> Repo.preload(:steps)
    |> Userflow.Public.steps_by_group()
  end

  @doc """
    Gets all progress for a user (Chapters or Pages).
  """
  def list_progress(%Manual.Model{userflow: userflow}, user_id) do
    Userflow.Public.list_progress(userflow, user_id)
  end

  def list_progress(%Manual.ChapterModel{userflow: userflow}, user_id) do
    Userflow.Public.list_progress(userflow, user_id)
  end

  @doc """
  Updates a manual page's content.
  """
  def update_page(%Manual.PageModel{} = page, attrs) do
    page
    |> Manual.PageModel.changeset(attrs)
    |> Repo.update()
  end

  def mark_visited(%Manual.ChapterModel{userflow_step: userflow_step}, user) do
    Userflow.Public.mark_visited(userflow_step, user)
  end

  def mark_visited(%Manual.PageModel{userflow_step: userflow_step}, user) do
    Userflow.Public.mark_visited(userflow_step, user)
  end
end
