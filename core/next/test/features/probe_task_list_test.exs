defmodule NextWeb.Features.ProbeTaskListTest do
  @moduledoc """
  Feature test for a participant doing a Cognitive screening (Probe) assignment in its
  horizontal task list, with a mock cognitive app in place of a real Feldspar app.
  """
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Systems.Assignment

  @mock_app_id "probe_mock_cognitive_app"
  @mock_app_source_path "next/test/systems/probe/mock_cognitive_app"

  @begin "[data-testid='task-intro-start']"
  @running_app "[data-testid='feldspar-tool-view'] [data-testid='app-container'].block"
  @close_modal "[data-testid='toolbar'] [phx-click='close_modal']"

  setup do
    upload_path = Application.get_env(:mica, :upload_path)
    target_path = Path.join(upload_path, @mock_app_id)
    File.mkdir_p!(target_path)
    File.cp_r!(Path.join(File.cwd!(), @mock_app_source_path), target_path)
    on_exit(fn -> File.rm_rf!(target_path) end)

    set_feature_flag(:probe, true)

    archive_ref = "#{Application.get_env(:mica, :base_url)}/feldspar/apps/#{@mock_app_id}"
    %{assignment: create_probe_assignment(archive_ref)}
  end

  @tag :feature
  feature "participant does the tasks in order and finishes after the last one", %{
    session: session,
    assignment: %{id: id} = assignment
  } do
    {session, user} = sign_in_as_new_user(session)
    Assignment.Public.add_participant!(assignment, user)

    session
    |> visit("/assignment/#{id}")
    |> assert_has(current_step(1))
    |> assert_connected(@begin)
    |> click(Query.css(@begin))
    |> assert_app_running()
    |> click(Query.css(@close_modal))
    |> assert_has(Query.css(@running_app, count: 0))
    |> assert_has(Query.css("[data-testid='task-intro']"))
    |> assert_has(current_step(1))
    |> click(Query.css(@begin))
    |> assert_app_running()
    |> finish_app()
    |> assert_has(current_step(2))
    |> visit("/assignment/#{id}")
    |> assert_has(current_step(2))
    |> assert_connected(@begin)
    |> click(Query.css(@begin))
    |> assert_app_running()
    |> finish_app()
    |> assert_has(Query.css("[data-testid='finished-title']"))
  end

  defp current_step(position) do
    Query.css("[data-testid='step-progress-step']:nth-child(#{position})[data-status='current']")
  end

  # The app loads in a fresh iframe and starts after the recovery check, which can take
  # longer than Wallaby's default wait, so allow up to three waits for it
  defp assert_app_running(session, waits \\ 3) do
    if waits > 1 and not has?(session, Query.css(@running_app)) do
      assert_app_running(session, waits - 1)
    else
      assert_has(session, Query.css(@running_app))
    end
  end

  defp finish_app(session) do
    session
    |> focus_frame(Query.css("[data-testid='feldspar-tool-view'] iframe"))
    |> click(Query.css("[data-testid='mock-finish']"))
    |> focus_default_frame()
  end

  defp create_probe_assignment(archive_ref) do
    auth_node = Factories.insert!(:auth_node)
    workflow = Assignment.Factories.create_workflow()

    for position <- [0, 1] do
      tool =
        Factories.insert!(:feldspar_tool, %{
          archive_ref: archive_ref,
          auth_node: Factories.insert!(:auth_node, %{parent: auth_node})
        })

      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool, special: :cognitive_tool})
      Assignment.Factories.create_workflow_item(workflow, tool_ref, "Task #{position}", position)
    end

    Factories.insert!(:assignment, %{
      info: Assignment.Factories.create_info("10", 100),
      consent_agreement: nil,
      workflow: workflow,
      crew: Factories.insert!(:crew),
      auth_node: auth_node,
      special: :probe,
      status: :online
    })
  end
end
