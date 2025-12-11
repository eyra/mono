defmodule Systems.Manual.Factories do
  use ExMachina.Ecto, repo: Core.Repo

  alias Systems.Manual
  alias Systems.Userflow

  def manual_factory do
    %Manual.Model{
      title: sequence(:title, &"Manual title #{&1}"),
      description: "Manual description"
    }
  end

  def chapter_factory do
    %Manual.ChapterModel{
      title: sequence(:title, &"Chapter title #{&1}")
    }
  end

  def page_factory do
    %Manual.PageModel{
      title: sequence(:title, &"Page title #{&1}"),
      text: "Page text",
      image: "Page image"
    }
  end

  def manual_tool_factory do
    %Manual.ToolModel{
      director: :assignment
    }
  end

  def create_manual(chapter_count \\ 1, page_count \\ 1) do
    manual_userflow = Userflow.Factories.insert(:userflow)
    manual = insert(:manual, %{userflow: manual_userflow})

    chapters =
      Enum.map(Range.new(1, chapter_count, 1), fn chapter_index ->
        chapter_step =
          Userflow.Factories.insert(:step, %{
            userflow: manual_userflow,
            group: "group-chapter-#{div(chapter_index, 2)}"
          })

        chapter_userflow = Userflow.Factories.insert(:userflow)

        chapter =
          insert(:chapter,
            manual: manual,
            userflow_step: chapter_step,
            userflow: chapter_userflow
          )

        pages =
          Enum.map(Range.new(1, page_count, 1), fn page_index ->
            page_step =
              Userflow.Factories.insert(:step, %{
                userflow: chapter_userflow,
                group: "group-page-#{div(page_index, 2)}"
              })

            page = insert(:page, chapter: chapter, userflow_step: page_step)
            %{page | userflow_step: page_step}
          end)

        %{chapter | userflow_step: chapter_step, userflow: chapter_userflow, pages: pages}
      end)

    %{manual | chapters: chapters}
  end

  def create_manual_tool(chapter_count \\ 1, page_count \\ 1, auth_node \\ insert(:auth_node)) do
    manual = create_manual(chapter_count, page_count)
    manual_tool = insert(:manual_tool, %{manual: manual, auth_node: auth_node})
    manual_tool
  end
end
