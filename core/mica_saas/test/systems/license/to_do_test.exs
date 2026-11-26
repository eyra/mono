defmodule MicaSaas.Systems.License.ToDoTest do
  @moduledoc """
  UC-LINK-02 part 2: the researcher's open To-do and Desktop pages show what
  support did with their licenses, the reminder before an end date and that a
  license ended, without a reload. Each license To-do is a notification:
  clicking its button marks it read and goes where it leads.
  """
  use MicaSaasWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test
  import Phoenix.LiveViewTest

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.License
  alias Systems.License.NextActions.Ended
  alias Systems.License.NextActions.Given
  alias Systems.License.NextActions.Reminder
  alias Systems.License.NextActions.SwitchedOff
  alias Systems.NextAction
  alias Systems.Notify

  setup [:login_as_creator]

  setup do
    set_feature_flag(:panl_post_launch, true)
    %{admin: Factories.insert!(:admin, %{email: "admin1@example.org"})}
  end

  defp end_date(period), do: License.Public.end_date(period)

  defp date(period), do: License.Public.format_date(end_date(period))

  # The button of the user's license To-do of `type`: it opens its notification
  # (`/notify/open/:id`), which marks it seen.
  defp button(user, type), do: ~m"/notify/open/#{message_id(user, type)}"

  defp message_id(%{id: user_id}, type) do
    %{params: %{"notify_message_id" => message_id}} =
      Repo.get_by!(NextAction.Model, user_id: user_id, action: to_string(type))

    message_id
  end

  defp to_do(user, type), do: "#next-actions a[href='#{button(user, type)}']"

  defp highlight(user, type),
    do: "[data-testid='next-action-highlight'] a[href='#{button(user, type)}']"

  test "the To-do page shows the license support gives", %{conn: conn, user: user, admin: admin} do
    {:ok, view, _html} = live(conn, ~m"/todo")
    assert has_element?(view, "#zero-todos")

    :ok = License.Public.save(admin, user, %{pay_in: {:on, end_date(:year_1)}})

    assert has_element?(
             view,
             to_do(user, Given),
             "You have the Pay-in license until #{date(:year_1)}"
           )
  end

  test "the To-do page shows the license support switches off", %{
    conn: conn,
    user: user,
    admin: admin
  } do
    :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})
    {:ok, view, _html} = live(conn, ~m"/todo")
    given = to_do(user, Given)
    assert has_element?(view, given)

    :ok = License.Public.save(admin, user, %{publish: :off})

    assert has_element?(
             view,
             to_do(user, SwitchedOff),
             "Your Publish license is switched off"
           )

    refute has_element?(view, given)
  end

  test "the Desktop shows the reminder, and the new end date once support extends the license",
       %{conn: conn, user: user, admin: admin} do
    valid_until = Date.add(License.Public.today(), 14)
    Factories.insert!(:license, %{user: user, valid_until: valid_until})
    1 = License.Public.remind()

    {:ok, view, _html} = live(conn, ~m"/desktop")

    reminder = highlight(user, Reminder)

    assert has_element?(
             view,
             reminder,
             "Your Publish license ends on #{License.Public.format_date(valid_until)}"
           )

    :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})

    refute has_element?(view, reminder)

    assert has_element?(
             view,
             highlight(user, Given),
             "You have the Publish license until #{date(:year_1)}"
           )
  end

  test "the Desktop shows that the license ended", %{conn: conn, user: user} do
    valid_until = Date.add(License.Public.today(), -1)
    Factories.insert!(:license, %{user: user, valid_until: valid_until})
    1 = License.Public.tell_ended()

    {:ok, view, _html} = live(conn, ~m"/desktop")

    assert has_element?(view, highlight(user, Ended), "Your Publish license has ended")
  end

  describe "clicking the button of a license To-do" do
    test "the given one marks it read and goes to Projects", %{
      conn: conn,
      user: user,
      admin: admin
    } do
      :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})

      assert redirected_to(post(conn, button(user, Given))) == "/project"
      assert NextAction.Public.list_next_actions(user) == []
    end

    test "the switched-off one marks it read and goes to the helpdesk page", %{
      conn: conn,
      user: user,
      admin: admin
    } do
      :ok = License.Public.save(admin, user, %{publish: {:on, end_date(:year_1)}})
      :ok = License.Public.save(admin, user, %{publish: :off})

      assert redirected_to(post(conn, button(user, SwitchedOff))) == "/support/helpdesk"
      assert NextAction.Public.list_next_actions(user) == []
    end

    test "the reminder marks it read and goes to the helpdesk page", %{conn: conn, user: user} do
      Factories.insert!(:license, %{user: user, valid_until: Date.add(License.Public.today(), 14)})

      1 = License.Public.remind()

      assert redirected_to(post(conn, button(user, Reminder))) == "/support/helpdesk"
      assert NextAction.Public.list_next_actions(user) == []
    end

    test "the ended one marks it read and goes to the helpdesk page", %{conn: conn, user: user} do
      Factories.insert!(:license, %{user: user, valid_until: Date.add(License.Public.today(), -1)})

      1 = License.Public.tell_ended()

      assert redirected_to(post(conn, button(user, Ended))) == "/support/helpdesk"
      assert NextAction.Public.list_next_actions(user) == []
    end

    test "makes the next unread one the Desktop's next best action, live", %{
      conn: conn,
      user: user,
      admin: admin
    } do
      :ok = License.Public.save(admin, user, %{pay_in: {:on, end_date(:year_1)}})

      Factories.insert!(:license, %{user: user, valid_until: Date.add(License.Public.today(), 14)})

      1 = License.Public.remind()

      {:ok, view, _html} = live(conn, ~m"/desktop")
      reminder = highlight(user, Reminder)
      assert has_element?(view, reminder)

      # The click (`Notify.Controller`), from another page of the same user.
      {:ok, "/support/helpdesk"} = Notify.Public.open_message(user, message_id(user, Reminder))

      assert has_element?(view, highlight(user, Given))
      refute has_element?(view, reminder)
    end
  end

  describe "the To-dos say" do
    test "which license support gave, and until when" do
      assert %{
               title: "You have the Publish license until 24 Feb 2027",
               description: "You can publish studies until then." <> _,
               cta_label: "Go to projects",
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

    test "which license ended and when, what is refused, and how to ask support" do
      assert %{
               title: "Your Publish license has ended",
               description:
                 "It ended on 25 Nov 2026. You can't publish new studies. Running studies keep running. Ask support through the helpdesk if you need it again.",
               cta_label: "Go to helpdesk",
               cta_action: %{type: :redirect, to: "/support/helpdesk"}
             } =
               Ended.to_view_model(1, %{
                 "license" => "publish",
                 "valid_until" => "2026-11-25"
               })

      assert %{
               description:
                 "It ended on 25 Nov 2026. New pay-ins are refused. Running studies keep running. Ask support through the helpdesk if you need it again."
             } =
               Ended.to_view_model(1, %{
                 "license" => "pay_in",
                 "valid_until" => "2026-11-25"
               })
    end

    test "each of them is a notification on the Actions channel" do
      for {type, options} <- License.Notify.notify_events() do
        assert Keyword.fetch!(options, :channels) == [:na], "#{type}"
        assert Keyword.has_key?(options, :next_action), "#{type}"
      end
    end
  end
end
