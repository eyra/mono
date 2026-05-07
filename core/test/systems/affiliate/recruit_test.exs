defmodule Systems.Affiliate.RecruitTest do
  use CoreWeb.ConnCase, async: false

  alias Systems.Assignment
  alias Systems.Affiliate

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

    test "returns 503 for offline assignment", %{conn: conn} do
      assignment =
        Assignment.Factories.create_assignment_with_affiliate()
        |> Ecto.Changeset.change(status: :concept)
        |> Core.Repo.update!()

      sqid = Affiliate.Sqids.encode!([0, assignment.id])
      conn = get(conn, "/r/#{sqid}")

      assert conn.status == 503
    end
  end
end
