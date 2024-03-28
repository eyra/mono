defmodule Systems.Assignment.ControllerTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Assignment

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
end
