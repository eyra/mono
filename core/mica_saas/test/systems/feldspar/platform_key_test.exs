defmodule MicaSaas.Systems.Feldspar.PlatformKeyTest do
  @moduledoc """
  Pins how a Feldspar workflow item's platform group reaches a donation: the
  upload context the tool view gives the client, and the identifier and file
  names the donation is stored under.

  code-registry moves `Workflow.Platforms` to Feldspar and Assignment's Feldspar
  handling behind `Mica.Tool` callbacks (plan.md, PR-6). This test must pass
  unchanged before and after: the key is host-only and stored data must not change.
  """
  use MicaSaasWeb.ConnCase, async: false
  use Oban.Testing, repo: Mica.Repo

  @moduletag :capture_log

  alias Systems.Assignment
  alias Systems.Feldspar
  alias Systems.Project
  alias Systems.Storage

  setup :login_as_member

  setup %{user: user} do
    assignment =
      Assignment.Factories.create_assignment(31, 0, :online)
      |> Project.Factories.link_storage_endpoint()

    Assignment.Public.add_participant!(assignment, user)
    {:ok, participant} = Assignment.Public.participant_id(assignment, user)

    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})

    %{assignment: assignment, participant: participant, tool: tool}
  end

  for {stored, key} <- [
        {"instagram", "instagram"},
        {"Instagram", "instagram"},
        {"chatgpt", "chatgpt"}
      ] do
    test "a Feldspar item with group #{inspect(stored)} donates under source=#{key}", %{
      conn: conn,
      assignment: assignment,
      participant: participant,
      tool: tool
    } do
      # The crew task view passes the workflow item's group to the tool view as its icon.
      vm =
        Feldspar.ToolViewBuilder.view_model(tool, %{
          title: "Donate",
          icon: unquote(stored),
          assignment_id: assignment.id,
          workflow_item_id: 456,
          participant: participant,
          recovery: %{scope: "scope", on_entry: :check, support_url: "mailto:support@example.org"}
        })

      upload_context = vm.app_view.options[:upload_context]
      assert upload_context.group == unquote(key)

      # The client posts that context with the donation (Feldspar.AppView).
      conn =
        post(conn, "/api/feldspar/donate", %{
          "key" => "donation-1",
          "data" => upload(~s({"test": "data"})),
          "context" => Jason.encode!(upload_context)
        })

      assert json_response(conn, 200) == %{"status" => "ok"}

      [%{args: %{"file_id" => file_id, "meta_data" => %{"identifier" => identifier}}}] =
        all_enqueued(worker: Storage.Delivery)

      assert identifier == [
               ["assignment", assignment.id],
               ["task", 456],
               ["participant", participant],
               ["source", unquote(key)],
               ["key", "donation-1"]
             ]

      prefix = "assignment=#{assignment.id}_task=456_participant=#{participant}"

      assert Storage.BuiltIn.Backend.filename(identifier) ==
               "#{prefix}_source=#{unquote(key)}_key=donation-1.json"

      # The temporary file takes its key from the context, which has none.
      assert file_id =~ ~r/^#{Regex.escape(prefix)}_source=#{unquote(key)}_\d+_\d+\.json$/
    end
  end

  test "a Feldspar item without a group donates without a source", %{
    conn: conn,
    assignment: assignment,
    participant: participant,
    tool: tool
  } do
    vm =
      Feldspar.ToolViewBuilder.view_model(tool, %{
        title: "Donate",
        icon: nil,
        assignment_id: assignment.id,
        workflow_item_id: 456,
        participant: participant,
        recovery: %{scope: "scope", on_entry: :check, support_url: "mailto:support@example.org"}
      })

    upload_context = vm.app_view.options[:upload_context]
    assert upload_context.group == nil

    conn =
      post(conn, "/api/feldspar/donate", %{
        "key" => "donation-1",
        "data" => upload(~s({"test": "data"})),
        "context" => Jason.encode!(upload_context)
      })

    assert json_response(conn, 200) == %{"status" => "ok"}

    [%{args: %{"meta_data" => %{"identifier" => identifier}}}] =
      all_enqueued(worker: Storage.Delivery)

    assert Storage.BuiltIn.Backend.filename(identifier) ==
             "assignment=#{assignment.id}_task=456_participant=#{participant}_key=donation-1.json"
  end

  defp upload(content) do
    path = Path.join(System.tmp_dir!(), "platform-key-#{System.unique_integer([:positive])}.json")
    File.write!(path, content)

    %Plug.Upload{path: path, filename: "data.json", content_type: "application/json"}
  end
end
