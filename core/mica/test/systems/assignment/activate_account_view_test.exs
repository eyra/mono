defmodule Systems.Assignment.ActivateAccountViewTest do
  use MicaWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Mica.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  setup %{conn: conn} do
    user = Factories.insert!(:member, %{confirmed_at: nil})

    context =
      LiveContext.new(%{
        current_user: user,
        locale: :en,
        timezone: "Etc/UTC",
        user_id: user.id
      })

    {:ok, conn: Map.put(conn, :request_path, "/assignment"), context: context}
  end

  test "resend survives the confirmation email the test mailer sends back to it",
       %{conn: conn, context: context} do
    {:ok, view, _html} =
      live_isolated(conn, Assignment.ActivateAccountView, session: %{"live_context" => context})

    render_click(view, "resend")

    # The LV reads the `{:delivered_email, _}` it sent itself while handling
    # the click before this render.
    assert render(view)
  end
end
