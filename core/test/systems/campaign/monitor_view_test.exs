defmodule Systems.Campaign.MonitorViewTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Core.Authorization
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Campaign,
    Crew
  }

  describe "show content page for campaign" do
    setup [:login_as_researcher]

    test "No member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id} = create_campaign(user, :accepted, 1)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Completed: 0"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 1"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end

    test "Member applied but expired and not completed", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task!(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Completed: 0"
      assert html =~ "Started: 1"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\"> 1"
      assert html =~ "Subject 1"
      assert html =~ "⚠️ Started:"
      assert html =~ "accept"
      assert html =~ "reject"
    end

    test "Member applied but expired and not completed: reject ", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task!(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =
        view
        |> element("[phx-click=\"reject\"]")
        |> render_click()

      assert html =~ "Completed: 0"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 1"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end

    test "Member applied but expired and not completed: accept ", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task!(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =
        view
        |> element("[phx-click=\"accept\"]")
        |> render_click()

      assert html =~ "Completed: 1"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end

    test "Member applied but expired and not completed: accept_all ", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 2)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)

      Crew.Context.update_task!(task, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      user2 = Factories.insert!(:member)
      {:ok, %{task: task2}} = Crew.Context.apply_member(crew, user2)

      Crew.Context.update_task!(task2, %{
        started_at: Timestamp.naive_from_now(-60),
        expire_at: Timestamp.naive_from_now(-31)
      })

      {:ok, view, _html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =
        view
        |> element("[phx-click=\"accept_all\"]")
        |> render_click()

      assert html =~ "Completed: 2"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end

    test "Member applied and completed", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, %{task: task}} = Crew.Context.apply_member(crew, user)
      Crew.Context.complete_task!(task)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Completed: 1"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 0"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end

    test "Member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} = create_campaign(user, :accepted, 1)

      {:ok, _} = Crew.Context.apply_member(crew, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Completed: 0"
      assert html =~ "Started: 0"
      assert html =~ "Applied: 1"
      assert html =~ "Open: 0"
      assert html =~ "Attention<span class=\"text-primary\"> 0"
    end
  end

  defp create_campaign(
         researcher,
         status,
         subject_count,
         schedule_start \\ nil,
         schedule_end \\ nil
       ) do
    promotion = Factories.insert!(:promotion)

    _submission =
      Factories.insert!(:submission, %{
        promotion: promotion,
        status: status,
        schedule_start: schedule_start,
        schedule_end: schedule_end
      })

    crew = Factories.insert!(:crew)
    survey_tool = Factories.insert!(:survey_tool, %{duration: "10", subject_count: subject_count})
    assignment = Factories.insert!(:assignment, %{survey_tool: survey_tool, crew: crew})
    campaign = Factories.insert!(:campaign, %{assignment: assignment, promotion: promotion})

    :ok = Authorization.assign_role(researcher, campaign, :owner)

    campaign
  end
end
