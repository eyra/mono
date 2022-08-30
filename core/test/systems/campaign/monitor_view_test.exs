defmodule Systems.Campaign.MonitorViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  import ExUnit.Assertions

  alias Core.Authorization
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Campaign,
    Crew,
    Budget
  }

  describe "show content page for campaign" do
    setup [:login_as_researcher]

    test "No member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id} = create_campaign(user, :accepted, 1)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 0"
      assert html =~ "Pending: 0"
      assert html =~ "Open: 1"
    end

    test "Member applied but expired and not completed", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 0"
      assert html =~ "Pending: 1"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\">\n            1"
      assert html =~ "Subject 1"
      assert html =~ "Started today at"
      assert html =~ "accept"
      assert html =~ "reject"
    end

    test "Member applied but expired and not completed: reject -> dialog", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =
        view
        |> element("[phx-click=\"reject\"]")
        |> render_click()

      assert html =~ "Reject contribution"
      assert html =~ "Message to participant"
    end

    test "Member applied but expired and not completed: accept ", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      _html =
        view
        |> element("[phx-click=\"accept\"]")
        |> render_click()

      assert_signals_dispatched(:crew_task_updated, 1)
    end

    test "Member applied but expired and not completed: accept_all", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 2)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      user2 = Factories.insert!(:member)
      {:ok, %{task: task2}} = Crew.Context.apply_member(crew, user2)

      Crew.Context.update_task(task2, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      _html =
        view
        |> element("[phx-click=\"accept_all_pending_started\"]")
        |> render_click()

      assert_signals_dispatched(:crew_task_updated, 2)
    end

    test "Member completed: accept_all", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 2)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task(task, %{
        status: :completed,
        completed_at: Timestamp.naive_now()
      })

      user2 = Factories.insert!(:member)
      {:ok, %{task: task2}} = Crew.Context.apply_member(crew, user2)

      Crew.Context.update_task(task2, %{
        status: :completed,
        completed_at: Timestamp.naive_now()
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      _html =
        view
        |> element("[phx-click=\"accept_all_completed\"]")
        |> render_click()

      assert_signals_dispatched(:crew_task_updated, 2)
    end

    test "Member applied and completed", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)
      Crew.Context.activate_task(task)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 1"
      assert html =~ "Pending: 0"
      assert html =~ "Open: 0"
    end

    test "Member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, _} = Crew.Context.apply_member(crew, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 0"
      assert html =~ "Pending: 1"
      assert html =~ "Open: 0"
    end
  end

  defp create_campaign(
         researcher,
         status,
         subject_count,
         schedule_start \\ nil,
         schedule_end \\ nil
       ) do
    currency = Budget.Factories.create_currency("test_1234", "ƒ", 2)
    budget = Budget.Factories.create_budget("test_1234", currency)
    pool = Factories.insert!(:pool, %{name: "test_1234", currency: currency})

    promotion = Factories.insert!(:promotion)

    submission =
      Factories.insert!(:submission, %{
        pool: pool,
        status: status,
        schedule_start: schedule_start,
        schedule_end: schedule_end
      })

    crew = Factories.insert!(:crew)
    survey_tool = Factories.insert!(:survey_tool)

    experiment =
      Factories.insert!(:experiment, %{
        survey_tool: survey_tool,
        duration: "10",
        subject_count: subject_count
      })

    assignment =
      Factories.insert!(:assignment, %{budget: budget, experiment: experiment, crew: crew})

    campaign =
      Factories.insert!(:campaign, %{
        assignment: assignment,
        promotion: promotion,
        submissions: [submission]
      })

    :ok = Authorization.assign_role(researcher, campaign, :owner)

    campaign
  end
end
