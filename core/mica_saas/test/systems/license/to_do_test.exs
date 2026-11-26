defmodule MicaSaas.Systems.License.ToDoTest do
  @moduledoc """
  UC-LINK-02 part 2: the researcher's open To-do and Desktop pages show what
  support did with their licenses, and the reminder before an end date,
  without a reload.
  """
  use MicaSaasWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test
  import Phoenix.LiveViewTest

  alias Mica.Factories
  alias Systems.License
  alias Systems.License.NextActions.Given
  alias Systems.License.NextActions.Reminder
  alias Systems.License.NextActions.SwitchedOff

  setup [:login_as_creator]

  setup do
    set_feature_flag(:panl_post_launch, true)
    %{admin: Factories.insert!(:admin, %{email: "admin1@example.org"})}
  end

  defp end_date(period), do: License.Public.end_date(period)

  defp date(period), do: License.Public.format_date(end_date(period))

  test "the To-do page shows the license support gives", %{conn: conn, user: user, admin: admin} do
    {:ok, view, _html} = live(conn, ~m"/todo")
    assert has_element?(view, "#zero-todos")

    :ok = License.Public.save(admin, user, %{pay_in: {:on, end_date(:year_1)}})

    assert render(view) =~ "You have the Pay-in license until #{date(:year_1)}"
    assert has_element?(view, "a[href='/project']", "Go to projects")
  end

  test "the To-do page shows the license support switches off, with the helpdesk",
       %{conn: conn, user: user, admin: admin} do
    :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})
    {:ok, view, html} = live(conn, ~m"/todo")
    assert html =~ "You have the Publish license until"

    :ok = License.Public.save(admin, user, %{publish: :off})

    html = render(view)
    assert html =~ "Your Publish license is switched off"
    assert html =~ "Running studies keep running."
    refute html =~ "You have the Publish license until"
    assert has_element?(view, "a[href='/support/helpdesk']", "Go to helpdesk")
  end

  describe "the To-dos say" do
    test "which license support gave, and until when" do
      assert %{
               title: "You have the Publish license until 24 Feb 2027",
               description: "You can publish studies until then." <> _,
               cta_action: %{type: :redirect, to: "/project"}
             } =
               Given.to_view_model(1, %{
                 "license" => "publish",
                 "valid_until" => "2027-02-24"
               })

      assert %{description: "You can pay in for studies until then." <> _} =
               Given.to_view_model(1, %{
                 "license" => "pay_in",
                 "valid_until" => "2027-02-24"
               })
    end

    test "which license support switched off, that running studies keep running, and how to ask support" do
      assert %{
               title: "Your Pay-in license is switched off",
               description:
                 "New pay-ins are refused. Running studies keep running. Ask support through the helpdesk if you need it again.",
               cta_label: "Go to helpdesk",
               cta_action: %{type: :redirect, to: "/support/helpdesk"}
             } = SwitchedOff.to_view_model(1, %{"license" => "pay_in"})

      assert %{
               description:
                 "You can't publish new studies. Running studies keep running. Ask support through the helpdesk if you need it again."
             } = SwitchedOff.to_view_model(1, %{"license" => "publish"})
    end

    test "which license ends and when, opening the helpdesk page" do
      assert %{
               title: "Your Pay-in license ends on 10 Dec 2026",
               description: "Ask support through the helpdesk to extend it.",
               cta_label: "Go to helpdesk",
               cta_action: %{type: :redirect, to: "/support/helpdesk"}
             } =
               Reminder.to_view_model(1, %{
                 "license" => "pay_in",
                 "valid_until" => "2026-12-10"
               })
    end
  end

  test "the Desktop shows the reminder, and the new end date once support extends the license",
       %{conn: conn, user: user, admin: admin} do
    valid_until = Date.add(License.Public.today(), 14)
    Factories.insert!(:license, %{user: user, valid_until: valid_until})
    1 = License.Public.remind()

    {:ok, view, html} = live(conn, ~m"/desktop")
    assert html =~ "Your Publish license ends on #{License.Public.format_date(valid_until)}"
    assert has_element?(view, "a[href='/support/helpdesk']", "Go to helpdesk")

    :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})

    html = render(view)
    refute html =~ "Your Publish license ends on"
    assert html =~ "You have the Publish license until #{date(:year_1)}"
  end
end
