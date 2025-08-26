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
    {:ok, %{manual: manual}} = create_manual()

    %Manual.ToolModel{}
    |> Manual.ToolModel.changeset(attrs)
    |> put_assoc(:manual, manual)
    |> put_assoc(:auth_node, auth_node)
  end

  def prepare_manual(%Userflow.Model{} = manual_userflow) do
    %Manual.Model{}
    |> Manual.Model.changeset(%{})
    |> put_assoc(:userflow, manual_userflow)
  end

  def prepare_chapter(
        %Manual.Model{} = manual,
        %Userflow.StepModel{} = chapter_userflow_step,
        %Userflow.Model{} = chapter_userflow,
        title
      ) do
    %Manual.ChapterModel{}
    |> Manual.ChapterModel.changeset(%{title: title})
    |> put_assoc(:manual, manual)
    |> put_assoc(:userflow_step, chapter_userflow_step)
    |> put_assoc(:userflow, chapter_userflow)
  end

  def prepare_page(
        %Manual.ChapterModel{} = chapter,
        %Userflow.StepModel{} = chapter_userflow_step,
        title
      ) do
    %Manual.PageModel{}
    |> Manual.PageModel.changeset(%{title: title})
    |> put_assoc(:chapter, chapter)
    |> put_assoc(:userflow_step, chapter_userflow_step)
  end

  def create_manual() do
    Multi.new()
    |> create_manual(:manual)
    |> Signal.Public.multi_dispatch({:manual, :created})
    |> Repo.transaction()
  end

  def create_manual(%Manual.ToolModel{} = tool) do
    Multi.new()
    |> create_manual(:manual)
    |> Multi.update(:manual_tool, fn %{manual: manual} ->
      tool
      |> Repo.preload(:manual)
      |> Manual.ToolModel.changeset(%{})
      |> put_assoc(:manual, manual |> Repo.preload(Manual.Model.preload_graph(:down)))
    end)
    |> Signal.Public.multi_dispatch({:manual_tool, :manual_created})
    |> Repo.transaction()
  end

  def create_manual(%Multi{} = multi, manual_name) do
    chapter_title = dgettext("eyra-manual", "chapter.title.first")
    chapter_label = dgettext("eyra-manual", "chapter.label.first")
    page_title = dgettext("eyra-manual", "page.title.first")

    multi
    |> Userflow.Assembly.create_userflow_and_step(
      :manual_userflow,
      :manual_userflow_step,
      chapter_label
    )
    |> Userflow.Assembly.create_userflow_and_step(:chapter_userflow, :chapter_userflow_step, nil)
    |> Multi.insert(manual_name, fn %{manual_userflow: manual_userflow} ->
      prepare_manual(manual_userflow)
    end)
    |> Multi.insert(:manual_chapter, fn %{
                                          manual_userflow_step: manual_userflow_step,
                                          chapter_userflow: chapter_userflow
                                        } = state ->
      manual = Map.get(state, manual_name)
      prepare_chapter(manual, manual_userflow_step, chapter_userflow, chapter_title)
    end)
    |> Multi.insert(:manual_page, fn %{
                                       manual_chapter: chapter,
                                       chapter_userflow_step: chapter_userflow_step
                                     } ->
      prepare_page(chapter, chapter_userflow_step, page_title)
    end)
  end

  def create_next_chapter(%Multi{} = multi, %Manual.Model{userflow: manual_userflow} = manual) do
    chapter_title = dgettext("eyra-manual", "chapter.title.default")
    chapter_label = nil
    page_title = dgettext("eyra-manual", "page.title.first")

    multi
    |> Multi.put(:manual_userflow, manual_userflow)
    |> Userflow.Assembly.create_next_step(:manual_userflow_step, :manual_userflow)
    |> Userflow.Assembly.create_userflow_and_step(
      :chapter_userflow,
      :chapter_userflow_step,
      chapter_label
    )
    |> Multi.insert(:manual_chapter, fn %{
                                          manual_userflow_step: manual_userflow_step,
                                          chapter_userflow: chapter_userflow
                                        } ->
      prepare_chapter(manual, manual_userflow_step, chapter_userflow, chapter_title)
    end)
    |> Multi.insert(:manual_page, fn %{
                                       manual_chapter: chapter,
                                       chapter_userflow_step: chapter_userflow_step
                                     } ->
      prepare_page(chapter, chapter_userflow_step, page_title)
    end)
  end

  def create_next_page(
        %Multi{} = multi,
        %Manual.ChapterModel{userflow: chapter_userflow} = chapter
      ) do
    page_title = dgettext("eyra-manual", "page.title.default")

    multi
    |> Multi.put(:userflow, chapter_userflow)
    |> Userflow.Assembly.create_next_step(:userflow_step, :userflow)
    |> Multi.insert(:manual_page, fn %{userflow_step: userflow_step} ->
      prepare_page(chapter, userflow_step, page_title)
    end)
  end
end
