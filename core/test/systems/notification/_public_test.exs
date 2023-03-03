defmodule Systems.Notification.PublicTest do
  use Core.DataCase
  alias Core.Factories
  alias Systems.Notification.Public
  doctest Systems.Notification.Public

  setup do
    %{user: Factories.insert!(:member)}
  end

  @notification %{
    title: "Test"
  }

  describe "notify/2" do
    test "notify user", %{user: user} do
      assert Public.notify(user, @notification) == :ok
    end

    test "notify accepts keyword argument", %{user: user} do
      assert Public.notify(user, title: "Nice") == :ok
    end

    test "sends message to multiple users", %{user: user} do
      another_user = Factories.insert!(:member)

      {:ok, _} = Public.notify([user, another_user], %{title: "Testing"})

      assert Public.list(user) |> Enum.map(& &1.title) == ["Testing"]
      assert Public.list(another_user) |> Enum.map(& &1.title) == ["Testing"]
    end
  end

  describe "list/1" do
    test "an empty list is returned when there are no notifications", %{user: user} do
      assert Public.list(user) == []
    end

    test "a list of notifications is returned when they have been notifyed", %{user: user} do
      :ok = Public.notify(user, @notification)

      assert Public.list(user) |> Enum.map(& &1.title) == ["Test"]
    end

    test "notifications are listed in reverse chronological order", %{user: user} do
      expected =
        for i <- 1..5 do
          title = "N#{i}"

          :ok =
            Public.notify(
              user,
              Map.merge(@notification, %{title: title})
            )

          title
        end
        |> Enum.reverse()

      assert Public.list(user) |> Enum.map(& &1.title) == expected
    end

    test "list notifications only matching the user they belong to" do
      users = 1..3 |> Enum.map(fn _ -> Factories.insert!(:member) end)

      titles =
        users
        |> Enum.map(fn user ->
          title = user.id |> Integer.to_string()
          :ok = Public.notify(user, Map.put(@notification, :title, title))
          title
        end)

      :ok =
        Enum.zip(titles, users)
        |> Enum.each(fn {title, user} ->
          assert Public.list(user) |> Enum.map(& &1.title) == [title]
        end)
    end

    test "archived notifications are no longer listed", %{user: user} do
      :ok = Public.notify(user, @notification)
      [%{id: id}] = Public.list(user)
      {:ok, _} = id |> Public.get() |> Public.mark(:archived)

      assert Public.list(user) == []
    end
  end

  describe "get/2" do
    test "fetch a single notification", %{user: user} do
      :ok = Public.notify(user, @notification)
      [%{id: notification_id}] = Public.list(user)
      assert Public.get(notification_id).title == @notification.title
    end
  end

  describe "mark/2" do
    setup %{user: user} do
      :ok = Public.notify(user, @notification)
      [%{id: notification_id}] = Public.list(user)
      %{notification: Public.get(notification_id)}
    end

    test "mark a notification as read changes it's status", %{notification: notification} do
      {:ok, _} = Public.mark(notification, :read)
      assert Public.get(notification.id).status == :read
    end

    test "mark a notification as archived changes it's status", %{notification: notification} do
      {:ok, _} = Public.mark(notification, :archived)
      assert Public.get(notification.id).status == :archived
    end
  end

  describe "notify_users_with_role/3" do
    test "sends message to users with matching role", %{user: user} do
      box = Public.get_or_create_box(user)

      {:ok, _} = Public.notify_users_with_role(box, :owner, %{title: "Testing"})

      assert Public.list(user) |> Enum.map(& &1.title) == ["Testing"]
    end
  end

  describe "mark_as_notified/1" do
    test "marking creates a record" do
      Public.mark_as_notified(Factories.insert!(:member), :test_example)
    end
  end

  describe "marked_as_notified?/1" do
    test "returns false when an item has not been marked" do
      refute Public.marked_as_notified?(Factories.insert!(:member), :test_example)
    end

    test "returns true when an item has been marked at least once" do
      item = Factories.insert!(:member)
      Public.mark_as_notified(item, :test_example)
      assert Public.marked_as_notified?(item, :test_example)
    end
  end
end
