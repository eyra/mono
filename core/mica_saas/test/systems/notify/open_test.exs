defmodule MicaSaas.Systems.Notify.OpenTest do
  @moduledoc """
  Every action is a notification: clicking the button of a next action that a
  notification shows on the Actions channel opens it (`/notify/open/:id`),
  which marks it seen and clears the next action, then goes where the button
  leads. Seen ones no longer show, the next best action is chosen from the
  ones left, and the next one takes its place. Uses License's notifications.
  """
  use MicaSaasWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.NextAction
  alias Systems.Notify

  setup [:login_as_creator]

  defp notify(user, type, license) do
    {:ok, _} =
      Notify.Public.record_event(%Notify.EventAttrs{
        type: type,
        subject_user: user,
        correlation_id: "license:#{license}",
        metadata: %{"license" => to_string(license), "valid_until" => "2027-11-26"}
      })

    message_id(user, type)
  end

  defp message_id(%{id: user_id}, type) do
    action = to_string(Notify.EventType.options_for(type)[:next_action])

    %{params: %{"notify_message_id" => message_id}} =
      Repo.get_by!(NextAction.Model, user_id: user_id, action: action)

    message_id
  end

  defp message(id), do: Repo.get!(Notify.MessageModel, id)

  describe "the button of a next action a notification shows" do
    test "opens the notification", %{user: user} do
      id = notify(user, :license_given, :publish)

      assert [%{cta_action: %{type: :http_post, to: to}}] =
               NextAction.Public.list_next_actions(user)

      assert to == "/notify/open/#{id}"
    end
  end

  # Opening changes state, so another site must not be able to trigger it: an
  # <img> or a link to it is a GET, a forged form has no valid CSRF token.
  describe "opening a notification from another site" do
    test "with a GET doesn't exist and marks nothing seen", %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)

      assert get(conn, "/notify/open/#{id}").status == 404

      assert %{status: :sent} = message(id)
      assert [_] = NextAction.Public.list_next_actions(user)
    end

    test "with a POST without a valid CSRF token is refused and marks nothing seen",
         %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)
      conn = Plug.Conn.put_private(conn, :plug_skip_csrf_protection, false)

      assert_raise Plug.CSRFProtection.InvalidCSRFTokenError, fn ->
        post(conn, ~m"/notify/open/#{id}", %{"_csrf_token" => "forged"})
      end

      assert %{status: :sent} = message(id)
      assert [_] = NextAction.Public.list_next_actions(user)
    end
  end

  describe "opening a notification" do
    test "marks it seen, keeps it and goes where the next action's button leads",
         %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)

      conn = post(conn, ~m"/notify/open/#{id}")

      assert redirected_to(conn) == "/project"
      assert %{status: :seen, seen_at: %DateTime{}} = message(id)
    end

    test "hides its next action from the To-do list, the count and the next best action",
         %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)

      post(conn, ~m"/notify/open/#{id}")

      assert NextAction.Public.list_next_actions(user) == []
      assert NextAction.Public.count_next_actions(user) == 0
      assert NextAction.Public.next_best_action(user) == nil
    end

    test "makes the next one, by priority, the next best action", %{conn: conn, user: user} do
      reminder = notify(user, :license_reminder, :publish)
      notify(user, :license_given, :pay_in)

      assert %{action_type: Systems.License.NextActions.Reminder} =
               NextAction.Public.next_best_action(user)

      post(conn, ~m"/notify/open/#{reminder}")

      assert %{action_type: Systems.License.NextActions.Given} =
               NextAction.Public.next_best_action(user)
    end

    test "a second time still goes where the button leads", %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)
      post(conn, ~m"/notify/open/#{id}")

      assert redirected_to(post(conn, ~m"/notify/open/#{id}")) == "/project"
    end

    test "of another user goes to the To-do page and changes nothing", %{conn: conn} do
      other = Factories.insert!(:creator)
      id = notify(other, :license_given, :publish)

      assert redirected_to(post(conn, ~m"/notify/open/#{id}")) == "/todo"
      assert %{status: :sent} = message(id)
      assert [_] = NextAction.Public.list_next_actions(other)
    end

    test "with an id that isn't a number goes to the To-do page", %{conn: conn} do
      assert redirected_to(post(conn, "/notify/open/abc")) == "/todo"
    end
  end

  describe "open pages" do
    test "the To-do page lists next actions without marking them seen",
         %{conn: conn, user: user} do
      id = notify(user, :license_given, :publish)

      {:ok, _view, html} = live(conn, ~m"/todo")

      assert html =~ "/notify/open/#{id}"
      assert %{status: :sent} = message(id)
    end

    test "after a click, the To-do page no longer lists it, live", %{conn: conn, user: user} do
      given = notify(user, :license_given, :publish)
      reminder = notify(user, :license_reminder, :pay_in)

      {:ok, view, _html} = live(conn, ~m"/todo")
      assert has_element?(view, "#next-actions a[href='/notify/open/#{given}']")

      # The click (`Notify.Controller`), from another page of the same user.
      {:ok, _} = Notify.Public.open_message(user, given)

      refute has_element?(view, "#next-actions a[href='/notify/open/#{given}']")
      assert has_element?(view, "#next-actions a[href='/notify/open/#{reminder}']")
    end

    test "after a click, the Desktop shows the next one as the next best action, live",
         %{conn: conn, user: user} do
      reminder = notify(user, :license_reminder, :publish)
      given = notify(user, :license_given, :pay_in)
      highlight = "[data-testid='next-action-highlight'] a[href='/notify/open/"

      {:ok, view, _html} = live(conn, ~m"/desktop")
      assert has_element?(view, highlight <> "#{reminder}']")

      {:ok, _} = Notify.Public.open_message(user, reminder)

      assert has_element?(view, highlight <> "#{given}']")
      refute has_element?(view, highlight <> "#{reminder}']")
    end
  end
end
