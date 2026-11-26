defmodule MicaSaas.Systems.Assignment.CrewPageToolViewsTest do
  @moduledoc """
  A task on the crew page shows what its tool shows on its own page. The crew task views
  give the tool view its tool without the tool's nested data.
  """
  use MicaSaasWeb.ConnCase, async: false
  use Gettext, backend: MicaWeb.Gettext
  import Phoenix.LiveViewTest
  import Systems.Assignment.CrewPageToolViewHelper

  alias Mica.Repo
  alias Systems.Alliance
  alias Systems.Content
  alias Systems.Document
  alias Systems.Feldspar
  alias Systems.Instruction
  alias Systems.Manual

  @participant "participant-1"

  setup :login_as_member

  test "an Instruction task shows the tool's instruction page", %{conn: conn, user: user} do
    tool =
      Repo.insert!(%Instruction.ToolModel{
        auth_node: Factories.build(:auth_node),
        pages: [
          %Instruction.PageModel{
            page: %Content.PageModel{
              auth_node: Factories.build(:auth_node),
              body: "<p>Fork the benchmark repository</p>"
            }
          }
        ]
      })

    tool_ref = Factories.insert!(:tool_ref, %{instruction_tool: tool, special: :fork_instruction})

    crew_task = open_crew_task(conn, tool_ref, user)

    assert crew_task == open_tool_view(conn, Instruction.ToolView, tool_ref, user)
    assert crew_task.text =~ "Fork the benchmark repository"
  end

  test "an Alliance task shows the tool's start screen", %{conn: conn, user: user} do
    tool = Factories.insert!(:alliance_tool, %{url: "https://example.org/survey"})
    tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool, special: :questionnaire})

    crew_task = open_crew_task(conn, tool_ref, user)

    tool_view =
      open_tool_view(conn, Alliance.ToolView, tool_ref, user, %{
        url: "https://example.org/survey?participant=#{@participant}",
        description: dgettext("eyra-alliance", "tool.description")
      })

    assert crew_task == tool_view
    assert crew_task.links == ["https://example.org/survey?participant=#{@participant}"]
  end

  test "a Document task shows the tool's document", %{conn: conn, user: user} do
    tool = Factories.insert!(:document_tool, %{ref: "https://example.org/document.pdf"})
    tool_ref = Factories.insert!(:tool_ref, %{document_tool: tool, special: :document})

    crew_task = open_crew_task(conn, tool_ref, user)

    assert crew_task == open_tool_view(conn, Document.ToolView, tool_ref, user)
    assert crew_task.text =~ task_title()
  end

  test "a Feldspar task shows the tool's start screen", %{conn: conn, user: user} do
    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.org/feldspar"})
    tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool, special: :donate})

    crew_task = open_crew_task(conn, tool_ref, user)

    tool_view =
      open_tool_view(conn, Feldspar.ToolView, tool_ref, user, %{
        assignment_id: nil,
        participant: @participant,
        workflow_item_id: nil,
        description: nil,
        recovery: %{scope: "scope", on_entry: :check, support_url: "mailto:support"}
      })

    assert crew_task == tool_view
    assert crew_task.text =~ dgettext("eyra-feldspar", "tool.button")
  end

  test "a Manual task shows the tool's manual", %{conn: conn, user: user} do
    tool = Manual.Factories.create_manual_tool(2, 3, Factories.insert!(:auth_node))
    tool_ref = Factories.insert!(:tool_ref, %{manual_tool: tool, special: :manual})
    %{manual: %{chapters: [chapter | _]}} = Repo.preload(tool, manual: :chapters)

    crew_task = open_crew_task(conn, tool_ref, user)

    assert crew_task == open_tool_view(conn, Manual.ToolView, tool_ref, user)
    assert crew_task.text =~ chapter.title
  end

  defp open_crew_task(conn, tool_ref, user) do
    assignment = create_assignment(tool_ref, user)
    panel_info = %{panel: :affiliate, redirect_url: nil, participant: @participant}

    {:ok, view, _html} =
      conn
      |> put_session(:panel_info, panel_info)
      |> live(~m"/assignment/#{assignment.id}")

    view |> render() |> crew_task_content()
  end

  defp open_tool_view(conn, tool_view, tool_ref, user, data \\ %{}) do
    conn = Map.put(conn, :request_path, "/tool")
    session = tool_view_session(tool_ref, user, data)

    {:ok, view, _html} = live_isolated(conn, tool_view, session: session)

    view |> render() |> tool_view_content()
  end
end
