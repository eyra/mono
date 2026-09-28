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

    test "recovery references are editable defaults, submitted normally, and reset for a new ticket",
         %{conn: conn} do
      params = %{
        assignment_id: "123",
        task_id: "456",
        title: "untrusted title",
        description: "untrusted description"
      }

      {:ok, view, _html} = live(conn, ~p"/support/helpdesk?#{params}")

      assert has_element?(view, "input[name='ticket_model[title]'][value='']")

      assert view
             |> element("textarea[name='ticket_model[description]']")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.text() == "assignment_id: 123\ntask_id: 456"

      assert Support.Public.list_tickets(:open) == []

      view
      |> form("form", ticket_model: %{title: "recovery ticket"})
      |> render_submit()

      assert [%{title: "recovery ticket", description: "assignment_id: 123\ntask_id: 456"}] =
               Support.Public.list_tickets(:open)

      render_click(view, "next")

      assert view
             |> element("textarea[name='ticket_model[description]']")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.text() == ""
    end

    test "malformed references do not become ticket content", %{conn: conn} do
      params = %{
        assignment_id: "123\n<script>alert('assignment')</script>",
        task_id: %{id: "456"},
        title: "untrusted title",
        description: "untrusted description"
      }

      {:ok, view, _html} = live(conn, ~p"/support/helpdesk?#{params}")

      assert has_element?(view, "input[name='ticket_model[title]'][value='']")

      assert view
             |> element("textarea[name='ticket_model[description]']")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.text() == ""

      view
      |> form("form", ticket_model: %{title: "my ticket", description: "my own description"})
      |> render_submit()

      assert [%{title: "my ticket", description: "my own description"}] =
               Support.Public.list_tickets(:open)
    end

    test "validation does not restore references over an edited description", %{conn: conn} do
      {:ok, view, _html} =
        live(conn, ~p"/support/helpdesk?assignment_id=123&task_id=456")

      view
      |> form("form", ticket_model: %{title: "", description: "my edited description"})
      |> render_submit()

      assert view
             |> element("textarea[name='ticket_model[description]']")
             |> render()
             |> Floki.parse_fragment!()
             |> Floki.text() == "my edited description"

      view
      |> form("form", ticket_model: %{title: "edited ticket"})
      |> render_submit()

      assert [%{title: "edited ticket", description: "my edited description"}] =
               Support.Public.list_tickets(:open)
    end
  end
end
