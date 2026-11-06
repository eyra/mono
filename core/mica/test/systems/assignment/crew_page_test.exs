defmodule Systems.Assignment.CrewPageTest do
  use MicaWeb.ConnCase
  use Oban.Testing, repo: Mica.Repo
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Manual
  alias Systems.Project
  alias Systems.Storage

  setup :login_as_member

  setup do
    advert_auth_node = Factories.insert!(:auth_node)
    assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
    tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

    tool = Assignment.Factories.create_tool(tool_auth_node)
    tool_ref = Assignment.Factories.create_tool_ref(tool)
    workflow = Assignment.Factories.create_workflow()
    _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
    info = Assignment.Factories.create_info("10", 100)

    assignment =
      Assignment.Factories.create_assignment(
        info,
        # consent_agreement
        nil,
        workflow,
        assignment_auth_node,
        :online
      )

    {:ok, assignment: assignment, tool: tool}
  end

  describe "render an assignment crew page" do
    test "renders page", %{conn: conn, assignment: assignment, user: user} do
      conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})
      Assignment.Public.add_participant!(assignment, user)

      {:ok, _view, html} = live(conn, ~p"/assignment/#{assignment.id}")
      assert html =~ "<div id=\"crew_page\""
    end
  end

  describe "render crew page with manual tool" do
    setup do
      advert_auth_node = Factories.insert!(:auth_node)
      assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
      tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

      # Create manual tool with chapters and pages
      manual_tool = Manual.Factories.create_manual_tool(2, 3, tool_auth_node)
      manual_tool = Mica.Repo.preload(manual_tool, manual: [chapters: [:pages]])
      manual = manual_tool.manual
      [chapter1, _chapter2] = manual.chapters

      # Create tool_ref for manual
      tool_ref =
        Factories.insert!(:tool_ref, %{
          manual_tool: manual_tool,
          special: :manual
        })

      workflow = Assignment.Factories.create_workflow()
      _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
      info = Assignment.Factories.create_info("10", 100)

      assignment =
        Assignment.Factories.create_assignment(
          info,
          nil,
          workflow,
          assignment_auth_node,
          :online
        )

      {:ok, assignment: assignment, manual: manual, chapter1: chapter1}
    end

    test "renders manual with local toolbar - debug HTML structure", %{
      conn: conn,
      assignment: assignment,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})

      Assignment.Public.add_participant!(assignment, user)

      # Set user state via connect params with proper key format
      user_state_key = "next://user-#{user.id}@localhost/manual/#{manual.id}/chapter"
      user_state = %{user_state_key => to_string(chapter1.id)}

      {:ok, _view, html} =
        conn
        |> put_connect_params(%{"user_state" => user_state})
        |> live(~p"/assignment/#{assignment.id}")

      assert html =~ "crew_page"
    end
  end

  describe "participant id in stored data" do
    setup %{user: user} do
      study =
        Assignment.Factories.create_assignment_with_affiliate()
        |> Ecto.Changeset.change(special: :data_donation)
        |> Mica.Repo.update!()
        |> Project.Factories.link_storage_endpoint()

      other = Factories.insert!(:member)
      Assignment.Public.add_participant!(study, other)
      {:ok, other_id} = Assignment.Public.participant_id(study, other)

      {:ok, study: study, other_id: other_id, user: user}
    end

    test "stores the consent record under the study's own participant id", %{
      conn: conn,
      study: study,
      other_id: other_id,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)
      {:ok, own_id} = Assignment.Public.participant_id(study, user)

      view = open_crew_page(conn, study, to_string(other_id))
      send_event(view, :accept, %{})

      assert delivered_participant() == own_id
    end

    test "stores task data under the study's own participant id", %{
      conn: conn,
      study: study,
      other_id: other_id,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)
      {:ok, own_id} = Assignment.Public.participant_id(study, user)

      view = open_crew_page(conn, study, to_string(other_id))
      send_event(view, :store, %{task: "1", key: "k", group: "g", data: "{}"})

      assert delivered_participant() == own_id
    end

    test "delivers a file under the study's own participant id", %{
      conn: conn,
      study: study,
      other_id: other_id,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)
      {:ok, own_id} = Assignment.Public.participant_id(study, user)

      view = open_crew_page(conn, study, to_string(other_id))
      send_event(view, :deliver_blob, %{task: "1", key: "k", group: "g", blob_id: "blob"})

      assert delivered_participant() == own_id
    end

    test "stores task data without the session's panel info", %{
      conn: conn,
      study: study,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)

      view = open_crew_page(conn, study, "ext_a")
      send_event(view, :store, %{task: "1", key: "k", group: "g", data: "{}"})

      [%{args: %{"meta_data" => meta_data}}] = all_enqueued(worker: Storage.Delivery)
      refute Map.has_key?(meta_data, "panel_info")
    end

    test "delivers a file without the session's panel info", %{
      conn: conn,
      study: study,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)

      view = open_crew_page(conn, study, "ext_a")
      send_event(view, :deliver_blob, %{task: "1", key: "k", group: "g", blob_id: "blob"})

      [%{args: %{"meta_data" => meta_data}}] = all_enqueued(worker: Storage.Delivery)
      refute Map.has_key?(meta_data, "panel_info")
    end

    test "stores a panel participant's data under their identifier at the study's affiliate", %{
      conn: conn,
      study: study,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)
      Assignment.Factories.add_affiliate_user(study, user, "ext_b")

      view = open_crew_page(conn, study, "ext_b")
      send_event(view, :store, %{task: "1", key: "k", group: "g", data: "{}"})

      assert delivered_participant() == "ext_b"
    end

    test "stores a tester's preview as preview", %{conn: conn, study: study, user: user} do
      Crew.Public.apply_member_with_role(study.crew, user, :tester)

      view = open_crew_page(conn, study, "preview")
      send_event(view, :store, %{task: "1", key: "k", group: "g", data: "{}"})

      assert delivered_participant() == "preview"
    end

    test "stores a participant's data under their own id in preview mode", %{
      conn: conn,
      study: study,
      user: user
    } do
      Assignment.Public.add_participant!(study, user)
      {:ok, own_id} = Assignment.Public.participant_id(study, user)

      view = open_crew_page(conn, study, "preview")
      send_event(view, :store, %{task: "1", key: "k", group: "g", data: "{}"})

      assert delivered_participant() == own_id
    end
  end

  defp open_crew_page(conn, assignment, panel_participant) do
    panel_info = %{panel: :affiliate, redirect_url: nil, participant: panel_participant}

    {:ok, view, _html} =
      conn |> put_session(:panel_info, panel_info) |> live(~p"/assignment/#{assignment.id}")

    view
  end

  defp send_event(view, name, payload) do
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: name, payload: payload}})
    # Wait until the page has handled the event
    render(view)
  end

  defp delivered_participant do
    [%{args: %{"meta_data" => %{"identifier" => identifier}}}] =
      all_enqueued(worker: Storage.Delivery)

    Enum.find_value(identifier, fn
      ["participant", participant] -> participant
      _ -> nil
    end)
  end
end
