defmodule Systems.Affiliate.RecruitTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  @moduletag :capture_log

  alias Systems.Assignment
  alias Systems.Affiliate
  alias Systems.Fund

  describe "GET /r/:sqid" do
    setup do
      assignment = Assignment.Factories.create_assignment_with_affiliate()
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      %{assignment: assignment, sqid: sqid}
    end

    test "redirects to affiliate URL with generated participant ID", %{conn: conn, sqid: sqid} do
      conn = get(conn, "/r/#{sqid}")

      assert redirected_to(conn) =~ "/a/#{sqid}?p=R_"
    end

    test "generated participant ID is unique per request", %{conn: conn, sqid: sqid} do
      conn1 = get(conn, "/r/#{sqid}")
      conn2 = get(Phoenix.ConnTest.build_conn(), "/r/#{sqid}")

      redirect1 = redirected_to(conn1)
      redirect2 = redirected_to(conn2)

      refute redirect1 == redirect2
    end

    test "returns 403 for invalid sqid", %{conn: conn} do
      conn = get(conn, "/r/invalid_sqid_123")

      assert conn.status == 403
    end

    test "returns 404 for deleted assignment", %{conn: conn} do
      assignment =
        Assignment.Factories.create_assignment_with_affiliate()
        |> Ecto.Changeset.change(status: :idle)
        |> Core.Repo.update!()

      sqid = Affiliate.Sqids.encode!([0, assignment.id])
      conn = get(conn, "/r/#{sqid}")

      assert conn.status == 404
    end

    test "shows a friendly 'not available' page for an unpublished assignment", %{conn: conn} do
      assignment =
        Assignment.Factories.create_assignment_with_affiliate()
        |> Ecto.Changeset.change(status: :concept)
        |> Core.Repo.update!()

      sqid = Affiliate.Sqids.encode!([0, assignment.id])
      conn = get(conn, "/r/#{sqid}")

      assert html_response(conn, 200) =~ "error-assignment_unavailable"
    end
  end

  describe "GET /a/:sqid (participant start)" do
    setup do
      assignment = Assignment.Factories.create_assignment_with_affiliate()
      %{assignment: assignment}
    end

    test "shows a friendly 'study is full' page when the budget cannot cover one more reward",
         %{conn: conn, assignment: assignment} do
      make_paid(assignment, 6000)
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=participant-full-1")

      response = html_response(conn, 200)
      assert response =~ "error-assignment_full"
      assert response =~ "This study is full"
    end

    test "starts the participant when the budget can cover one more reward",
         %{conn: conn, assignment: assignment} do
      make_paid(assignment, 100)
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=participant-ok-1")

      assert redirected_to(conn) == "/assignment/#{assignment.id}"
    end

    test "shows a friendly 'not available' page to a signed out visitor",
         %{conn: conn, assignment: assignment} do
      assignment
      |> Ecto.Changeset.change(status: :concept)
      |> Core.Repo.update!()

      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=participant-unavailable-1")

      response = html_response(conn, 200)
      assert response =~ "error-assignment_unavailable"
      assert response =~ "This study is not available"
    end
  end

  describe "GET /a/:sqid (study preview)" do
    setup :login_as_member

    test "an owner can preview a new unpublished assignment", %{conn: conn, user: user} do
      assignment = unpublished_assignment()
      :ok = Core.Authorization.assign_role(user, assignment, :owner)
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")

      assert redirected_to(conn) == "/assignment/#{assignment.id}"
      assert Assignment.Public.tester?(assignment, user)
    end

    test "an owner who never opened the CMS page sees the tasks in the preview",
         %{conn: conn, user: user} do
      assignment = unpublished_assignment()
      :ok = Core.Authorization.assign_role(user, assignment, :owner)
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")
      {:ok, _view, html} = live(conn, redirected_to(conn))

      assert html =~ "Test Task"
    end

    test "an owner who is already a crew member can preview without the tester role",
         %{conn: conn, user: user} do
      assignment = unpublished_assignment()
      :ok = Core.Authorization.assign_role(user, assignment, :owner)
      Systems.Crew.Factories.create_member(assignment.crew, user)
      refute Assignment.Public.tester?(assignment, user)
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")

      assert redirected_to(conn) == "/assignment/#{assignment.id}"
      assert Assignment.Public.tester?(assignment, user)
    end

    test "a user without access still sees that the assignment is unavailable",
         %{conn: conn} do
      assignment = unpublished_assignment()
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")

      assert html_response(conn, 200) =~ "This study is not available"
    end

    test "a user without access cannot join a live study through the preview link",
         %{conn: conn, user: user} do
      assignment = live_assignment()
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")

      assert html_response(conn, 200) =~ "This study is not available"
      assert conn.assigns.current_user.id == user.id
      refute Assignment.Public.member?(assignment, user)
      refute Assignment.Public.tester?(assignment, user)
      assert Affiliate.Public.get_user(assignment.affiliate, "preview") == nil
    end
  end

  describe "GET /a/:sqid?p=preview (signed out)" do
    test "a visitor cannot join a live study through the preview link", %{conn: conn} do
      assignment = live_assignment()
      sqid = Affiliate.Sqids.encode!([0, assignment.id])

      conn = get(conn, "/a/#{sqid}?p=preview")

      assert html_response(conn, 200) =~ "This study is not available"
      assert get_session(conn, :user_token) == nil
      assert Affiliate.Public.get_user(assignment.affiliate, "preview") == nil
    end
  end

  defp live_assignment do
    assignment = Assignment.Factories.create_assignment_with_affiliate()
    assert assignment.status == :online
    assignment
  end

  defp unpublished_assignment do
    Assignment.Factories.create_assignment_with_affiliate()
    |> Ecto.Changeset.change(status: :concept)
    |> Core.Repo.update!()
    |> Core.Repo.preload([:crew], force: true)
  end

  defp make_paid(%{info: info} = assignment, subject_reward) do
    currency = Fund.Factories.create_currency("eur_aff_#{subject_reward}", :legal, "€", 2)
    fund = Fund.Factories.create_fund("aff_fund_#{subject_reward}", currency)

    assignment
    |> Assignment.Model.changeset(fund)
    |> Core.Repo.update!()

    info
    |> Ecto.Changeset.change(subject_reward: subject_reward)
    |> Core.Repo.update!()
  end
end
