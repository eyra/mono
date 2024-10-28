defmodule Systems.Assignment.ControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Monitor

  describe "invite member" do
    setup :login_as_member

    test "assignment not published", %{conn: conn} do
      %{id: id} = Assignment.Factories.create_assignment(31, 0, :offline)

      conn = get(conn, "/assignment/#{id}/invite")
      html_response(conn, 503)
    end

    test "assignment published", %{conn: conn} do
      %{id: id} = Assignment.Factories.create_assignment(31, 0, :online)

      conn = get(conn, "/assignment/#{id}/invite")
      response = html_response(conn, 302)
      assert response =~ "href=\"/assignment/#{id}"
    end

    test "assignment not existing", %{conn: conn} do
      conn = get(conn, "/assignment/1/invite")
      html_response(conn, 503)
    end
  end

  describe "invite visitor" do
    test "assignment not published", %{conn: conn} do
      %{id: id} = Assignment.Factories.create_assignment(31, 0, :offline)

      conn = get(conn, "/assignment/#{id}/invite")
      response = html_response(conn, 302)
      assert response =~ "href=\"/user/signin"
    end

    test "assignment published", %{conn: conn} do
      %{id: id} = Assignment.Factories.create_assignment(31, 0, :online)

      conn = get(conn, "/assignment/#{id}/invite")
      response = html_response(conn, 302)
      assert response =~ "href=\"/user/signin"
    end

    test "assignment not existing", %{conn: conn} do
      conn = get(conn, "/assignment/1/invite")
      response = html_response(conn, 302)
      assert response =~ "href=\"/user/signin"
    end
  end

  describe "progress report" do
    test "progress_headers/1, no tasks + consent" do
      assert Assignment.Controller.progress_headers([], true) == [
               "Participant",
               "Consent"
             ]
    end

    test "progress_headers/1, no tasks - consent" do
      assert Assignment.Controller.progress_headers([], false) == [
               "Participant"
             ]
    end

    test "progress_headers/1, 2 tasks + consent" do
      workflow = Workflow.Factories.create_workflow()

      workflow_items =
        ["Task 1", "Task 2"]
        |> Enum.map(&Factories.insert!(:workflow_item, %{workflow: workflow, title: &1}))

      assert [
               "Participant",
               "Consent",
               "Task 1",
               "Task 2"
             ] == Assignment.Controller.progress_headers(workflow_items, true)
    end

    test "progress_csv_data/6" do
      assignment =
        %{crew: crew, workflow: workflow} = Assignment.Factories.create_assignment(31, 0)

      workflow_items =
        [%{id: item_1_id}, %{id: item_2_id}] =
        ["Task 1", "Task 2"]
        |> Enum.map(&Factories.insert!(:workflow_item, %{workflow: workflow, title: &1}))

      participants = [
        %{user_id: 1, member_id: 1, public_id: 777, external_id: nil},
        %{user_id: 2, member_id: 2, public_id: 778, external_id: "melle"},
        %{user_id: 3, member_id: 3, public_id: 779, external_id: nil}
      ]

      headers = ["Participant", "Consent", "Task 1", "Task 2"]
      signatures = [2]
      show_consent? = true

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_1_id}", "member=1"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        rejected_at: ~N[2024-09-30 19:36:39],
        status: :rejected
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_2_id}", "member=1"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        status: :pending
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_1_id}", "member=2"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        accepted_at: ~N[2024-09-30 19:36:39],
        status: :accepted
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_2_id}", "member=2"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        status: :completed
      })

      Monitor.Factories.create_monitor_event_consent_declined(assignment, 3)

      csv_data =
        Assignment.Controller.progress_csv_data(
          assignment,
          headers,
          participants,
          workflow_items,
          signatures,
          show_consent?
        )

      assert [
               "Participant,Consent,Task 1,Task 2\r\n",
               "777,n/a,rejected,started\r\n",
               "melle,yes,accepted,finished\r\n",
               "779,no,n/a,n/a\r\n"
             ] = csv_data
    end
  end

  describe "export progress report" do
    setup :login_as_member

    test "export/2", %{conn: conn} do
      user1 = Factories.insert!(:member)

      %{user: user2} = Factories.insert!(:external_user, %{external_id: "melle"})

      user3 = Factories.insert!(:member)

      crew_auth_node =
        Factories.build(:auth_node, %{
          role_assignments: [
            Factories.build(:participant, %{user: user1}),
            Factories.build(:participant, %{user: user2}),
            Factories.build(:participant, %{user: user3})
          ]
        })

      crew = Factories.insert!(:crew, %{auth_node: crew_auth_node})

      consent_agreement =
        Factories.insert!(:consent_agreement, %{
          revisions: [
            %{
              source: "Consent agreement v1",
              signatures: [
                %{user: user2}
              ]
            }
          ]
        })

      assignment =
        %{workflow: workflow} =
        Factories.insert!(:assignment, %{
          crew: crew,
          special: :data_donation,
          status: :online,
          consent_agreement: consent_agreement
        })

      [%{id: item_1_id}, %{id: item_2_id}] =
        ["Task 1", "Task 2"]
        |> Enum.map(&Factories.insert!(:workflow_item, %{workflow: workflow, title: &1}))

      member_1 = Factories.insert!(:crew_member, %{crew: crew, user: user1})
      member_2 = Factories.insert!(:crew_member, %{crew: crew, user: user2})
      _member_3 = Factories.insert!(:crew_member, %{crew: crew, user: user3})

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_1_id}", "member=#{member_1.id}"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        rejected_at: ~N[2024-09-30 19:36:39],
        status: :rejected
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_2_id}", "member=#{member_1.id}"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        status: :pending
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_1_id}", "member=#{member_2.id}"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        accepted_at: ~N[2024-09-30 19:36:39],
        status: :accepted
      })

      Factories.insert!(:crew_task, %{
        identifier: ["item=#{item_2_id}", "member=#{member_2.id}"],
        crew: crew,
        auth_node: %Core.Authorization.Node{},
        started_at: ~N[2024-09-30 19:36:39],
        completed_at: ~N[2024-09-30 19:36:39],
        status: :completed
      })

      Monitor.Factories.create_monitor_event_consent_declined(assignment, user3.id)

      response =
        conn
        |> Plug.Conn.assign(:branch, nil)
        |> Assignment.Controller.export(%{"id" => "#{assignment.id}"})

      assert response.resp_body =~ "Participant,Consent,Task 1,Task 2\r\n"
      assert response.resp_body =~ "melle,yes,accepted,finished\r\n"
      assert response.resp_body =~ "1,n/a,rejected,started\r\n"
      assert response.resp_body =~ "3,no,n/a,n/a\r\n"
    end
  end
end
