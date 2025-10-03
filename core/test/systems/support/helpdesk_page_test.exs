defmodule Systems.Support.HelpdeskPageTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias Systems.Support

  setup [:login_as_member]

  describe "create support ticket" do
    test "a member can submit a new ticket", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/support/helpdesk")

      view
      |> element("form")
      |> render_submit(%{
        ticket_model: %{title: "my ticket", description: "a ticket description"}
      })

      assert %{description: "a ticket description"} =
               Support.Public.list_tickets(:open) |> Enum.find(&(&1.title == "my ticket"))
    end
  end
end
