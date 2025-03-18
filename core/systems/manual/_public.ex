defmodule Systems.Manual.Public do
  use Core, :public

  import Systems.Manual.Assembly, only: [create_next_chapter: 2, create_next_page: 2]

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Manual
  alias Systems.Userflow

  @doc """
    Gets a tool by its id.
  """
  def get_tool!(id) do
    Repo.get!(Manual.ToolModel, id)
  end

  @doc """
    Gets the tool associated with a manual.
  """
  def get_tool_by_manual(%Manual.Model{} = manual) do
    Repo.get_by(Manual.ToolModel, manual_id: manual.id)
  end

  @doc """
  Gets a manual by its id.
  """
  def get_manual!(id, preload \\ []) do
    Manual.Queries.get_by_id(id)
    |> Repo.one!()
    |> Repo.preload(preload)
  end

  def get_chapter!(chapter_id) do
    Repo.get!(Manual.ChapterModel, chapter_id)
  end

  def get_chapter_by_step(%Userflow.StepModel{id: step_id}) do
    Manual.Queries.get_chapter_by_userflow_step(step_id)
    |> Repo.one()
  end

  @doc """
    Adds a chapter to a manual.
  """
  def add_chapter(%Manual.Model{} = manual) do
    Multi.new()
    |> create_next_chapter(manual)
    |> Signal.Public.multi_dispatch({:manual_chapter, :inserted})
    |> Repo.transaction()
  end

  def remove_chapter(chapter) do
    Multi.new()
    |> remove_chapter(chapter)
    |> Repo.transaction()
  end

  def remove_chapter(%Multi{} = multi, chapter) do
    multi
    |> Multi.delete(:manual_chapter, chapter)
    |> Signal.Public.multi_dispatch({:manual_chapter, :deleted})
  end

  @doc """
  Gets all chapters in a manual.
  """
  def get_chapters(manual) do
    Manual.Queries.get_chapters(manual.id)
    |> Repo.all()
  end

  @doc """
  Moves a chapter up in the manual.
  """
  def move_chapter(%Manual.ChapterModel{userflow_step: userflow_step}, :up) do
    Userflow.Public.move_step(userflow_step, :up)
  end

  @doc """
  Moves a chapter down in the manual.
  """

  def get_page_by_step(%Userflow.StepModel{id: step_id}) do
    Manual.Queries.get_page_by_userflow_step(step_id)
    |> Repo.one()
  end

  @doc """
    Adds a page to a chapter.
  """
  def add_page(%Manual.ChapterModel{} = chapter) do
    Multi.new()
    |> create_next_page(chapter)
    |> Signal.Public.multi_dispatch({:manual_page, :inserted})
    |> Repo.transaction()
  end

  @doc """
    Deletes a page from a chapter.
  """
  def delete_page(%Manual.PageModel{} = page) do
    Multi.new()
    |> delete_page(page)
    |> Repo.transaction()
  end

  @doc """
    Deletes a page from a chapter.
  """
  def delete_page(%Multi{} = multi, %Manual.PageModel{} = page) do
    multi
    |> Multi.delete(:manual_page, page)
    |> Signal.Public.multi_dispatch({:manual_page, :deleted})
  end

  @doc """
    Moves a page up in the chapter.
  """
  def move_page(%Manual.PageModel{userflow_step: userflow_step}, :up) do
    Userflow.Public.move_step(userflow_step, :up)
  end

  @doc """

  @doc \"""
  Gets the next unvisited chapter for a user in a manual.
  """
  def next_chapter(%Manual.Model{userflow: manual_userflow}, user) do
    case Userflow.Public.next_step(manual_userflow, user.id) do
      nil ->
        nil

      step ->
        get_chapter_by_step(step)
    end
  end

  @doc """
  Gets the next unvisited step for a user in a chapter.
  """
  def next_page(%Manual.ChapterModel{userflow: chapter_userflow}, user) do
    step = Userflow.Public.next_step(chapter_userflow, user.id)
    get_page_by_step(step)
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
