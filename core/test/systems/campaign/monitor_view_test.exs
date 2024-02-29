defmodule Systems.Campaign.MonitorViewTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  import ExUnit.Assertions

  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Campaign,
    Crew
  }

  describe "show content page for campaign" do
    setup [:login_as_researcher]

    test "No member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id} = Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 0"
      assert html =~ "Pending: 0"
      assert html =~ "Open: 1"
    end

    test "Member applied but expired and not completed", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])

      Crew.Public.update_task(
        task,
        %{
          started_at: Timestamp.naive_from_now(-60),
          expire_at: Timestamp.naive_from_now(-31)
        },
        :locked
      )

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
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])

      Crew.Public.update_task(
        task,
        %{
          started_at: Timestamp.naive_from_now(-60),
          expire_at: Timestamp.naive_from_now(-31)
        },
        :locked
      )

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
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])

      Crew.Public.update_task(
        task,
        %{
          started_at: Timestamp.naive_from_now(-60),
          expire_at: Timestamp.naive_from_now(-31)
        },
        :locked
      )

      {:ok, view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =~ "Goedgekeurd<span class=\"text-primary\">0"

      html =
        view
        |> element("[phx-click=\"accept\"]")
        |> render_click()

      html =~ "Goedgekeurd<span class=\"text-primary\">1"
    end

    test "Member applied but expired and not completed: accept_all", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 2)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])

      Crew.Public.update_task(
        task,
        %{
          started_at: Timestamp.naive_from_now(-60),
          expire_at: Timestamp.naive_from_now(-31)
        },
        :locked
      )

      user2 = Factories.insert!(:member)
      {:ok, %{crew_task: task2}} = Crew.Public.apply_member(crew, user2, ["task2"])

      Crew.Public.update_task(
        task2,
        %{
          started_at: Timestamp.naive_from_now(-60),
          expire_at: Timestamp.naive_from_now(-31)
        },
        :locked
      )

      {:ok, view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =~ "Goedgekeurd<span class=\"text-primary\">0"

      html =
        view
        |> element("[phx-click=\"accept_all_pending_started\"]")
        |> render_click()

      html =~ "Goedgekeurd<span class=\"text-primary\">2"
    end

    test "Member completed: accept_all", %{
      conn: %{assigns: %{current_user: user}} = conn
    } do
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 2)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])

      Crew.Public.update_task(
        task,
        %{
          status: :completed,
          completed_at: Timestamp.naive_now()
        },
        :locked
      )

      user2 = Factories.insert!(:member)
      {:ok, %{crew_task: task2}} = Crew.Public.apply_member(crew, user2, ["task2"])

      Crew.Public.update_task(
        task2,
        %{
          status: :completed,
          completed_at: Timestamp.naive_now()
        },
        :locked
      )

      {:ok, view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      html =~ "Goedgekeurd<span class=\"text-primary\">0"

      html =
        view
        |> element("[phx-click=\"accept_all_completed\"]")
        |> render_click()

      html =~ "Goedgekeurd<span class=\"text-primary\">2"
    end

    test "Member applied and completed", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, %{crew_task: task}} = Crew.Public.apply_member(crew, user, ["task1"])
      Crew.Public.activate_task(task)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 1"
      assert html =~ "Pending: 0"
      assert html =~ "Open: 0"
    end

    test "Member applied", %{conn: %{assigns: %{current_user: user}} = conn} do
      %{id: id, promotable_assignment: %{crew: crew}} =
        Campaign.Factories.create_campaign(user, :accepted, 1)

      {:ok, _} = Crew.Public.apply_member(crew, user, ["task1"])

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Campaign.ContentPage, id))

      assert html =~ "Participated: 0"
      assert html =~ "Pending: 1"
      assert html =~ "Open: 0"
    end
  end
end
