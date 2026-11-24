defmodule MicaSaas.Systems.Feldspar.ParticipantTaskTest do
  @moduledoc """
  The `participant_task` a Feldspar Tool gets in `live-init`: a keyed hash of the host's
  value, derived from the endpoint's secret_key_base, so it needs a SaaS.
  """
  use MicaSaasWeb.ConnCase, async: true

  alias Frameworks.Concept.LiveContext
  alias Systems.Feldspar

  setup do
    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
    %{tool: tool}
  end

  test "the Tool gets a 128-bit base64url value", %{tool: tool} do
    assert tool_participant_task(tool, "81234") =~ ~r/\A[A-Za-z0-9_-]{22}\z/
  end

  test "the Tool's value doesn't contain the host's id", %{tool: tool} do
    refute tool_participant_task(tool, "81234") =~ "81234"
  end

  test "the Tool's value is the same for the same task", %{tool: tool} do
    assert tool_participant_task(tool, "81234") == tool_participant_task(tool, "81234")
  end

  test "the Tool's value differs for another task", %{tool: tool} do
    refute tool_participant_task(tool, "81234") == tool_participant_task(tool, "81235")
  end

  defp tool_participant_task(tool, participant_task) do
    assigns = %{
      title: "Test App",
      icon: nil,
      recovery: %{scope: "scope", on_entry: :check, support_url: "mailto:support@example.org"},
      live_context: LiveContext.new(%{participant_task: participant_task})
    }

    %{app_view: %{options: options}} = Feldspar.ToolViewBuilder.view_model(tool, assigns)
    options[:participant_task]
  end
end
