defmodule Systems.Manual.Assembly do
  use Core, :auth
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset, only: [put_assoc: 3]

  alias Core.Repo
  alias Ecto.Multi

  alias Frameworks.Signal
  alias Systems.Manual
  alias Systems.Userflow

  def prepare_tool(%{} = attrs, auth_node \\ auth_module().prepare_node()) do
    chapter_title = dgettext("eyra-manual", "chapter.title.first")
    chapter_label = dgettext("eyra-manual", "chapter.label.first")
    page_title = dgettext("eyra-manual", "page.title.first")

    manual = prepare_manual(chapter_title, chapter_label, page_title)

    %Manual.ToolModel{}
    |> Manual.ToolModel.changeset(attrs)
    |> put_assoc(:manual, manual)
    |> put_assoc(:auth_node, auth_node)
  end

  def prepare_manual(chapter_title, chapter_label, page_title) do
    userflow = Userflow.Assembly.prepare_userflow()
    chapter = prepare_first_chapter(userflow, chapter_title, chapter_label, page_title)

    %Manual.Model{}
    |> Manual.Model.changeset(%{})
    |> put_assoc(:userflow, userflow)
    |> put_assoc(:chapters, [chapter])
  end

  def prepare_first_chapter(userflow, title, label, page_title) do
    userflow_step = Userflow.Assembly.prepare_step(userflow, 0, label)
    userflow = Userflow.Assembly.prepare_userflow()
    page = prepare_first_page(userflow, page_title)

    %Manual.ChapterModel{}
    |> Manual.ChapterModel.changeset(%{title: title})
    |> put_assoc(:userflow_step, userflow_step)
    |> put_assoc(:userflow, userflow)
    |> put_assoc(:pages, [page])
  end

  def prepare_next_chapter(%Manual.Model{userflow: manual_userflow} = manual, order) do
    title = dgettext("eyra-manual", "chapter.title.default")
    page_title = dgettext("eyra-manual", "page.title.first")

    userflow_step = Userflow.Assembly.prepare_step(manual_userflow, order, nil)
    userflow = Userflow.Assembly.prepare_userflow()
    page = prepare_first_page(userflow, page_title)

    %Manual.ChapterModel{}
    |> Manual.ChapterModel.changeset(%{title: title})
    |> put_assoc(:manual, manual)
    |> put_assoc(:userflow_step, userflow_step)
    |> put_assoc(:userflow, userflow)
    |> put_assoc(:pages, [page])
  end

  def prepare_first_page(userflow, title) do
    userflow_step = Userflow.Assembly.prepare_step(userflow, 0, nil)

    %Manual.PageModel{}
    |> Manual.PageModel.changeset(%{title: title})
    |> put_assoc(:userflow_step, userflow_step)
  end

  def prepare_next_page(%Manual.ChapterModel{userflow: chapter_userflow} = chapter, order) do
    title = dgettext("eyra-manual", "page.title.default")
    userflow_step = Userflow.Assembly.prepare_step(chapter_userflow, order, nil)

    %Manual.PageModel{}
    |> Manual.PageModel.changeset(%{title: title})
    |> put_assoc(:chapter, chapter)
    |> put_assoc(:userflow_step, userflow_step)
  end

  def create_manual(%Manual.ToolModel{} = tool) do
    chapter_title = dgettext("eyra-manual", "chapter.title.first")
    chapter_label = dgettext("eyra-manual", "chapter.label.first")
    page_title = dgettext("eyra-manual", "page.title.first")

    Multi.new()
    |> Multi.insert(:manual, prepare_manual(chapter_title, chapter_label, page_title))
    |> Multi.update(:manual_tool, fn %{manual: manual} ->
      tool
      |> Repo.preload(:manual)
      |> Manual.ToolModel.changeset(%{})
      |> put_assoc(:manual, manual |> Repo.preload(Manual.Model.preload_graph(:down)))
    end)
    |> Signal.Public.multi_dispatch({:manual_tool, :manual_created})
    |> Repo.transaction()
  end

  def create_manual() do
    chapter_title = dgettext("eyra-manual", "chapter.title.first")
    chapter_label = dgettext("eyra-manual", "chapter.label.first")
    page_title = dgettext("eyra-manual", "page.title.first")

    Multi.new()
    |> Multi.insert(:manual, prepare_manual(chapter_title, chapter_label, page_title))
    |> Signal.Public.multi_dispatch({:manual, :manual_created})
    |> Repo.transaction()
  end
end
