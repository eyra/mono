defmodule Systems.Desktop.SwitchTest do
  @moduledoc """
  Regression coverage for FX#9905887344 — the Desktop page must rebuild
  its view model when the current user's NextActions change so the
  next-best-action banner disappears live (in addition to the to-do
  count badge that the menus live-hook already refreshes).
  """
  use Core.DataCase, async: false

  alias Core.Factories
  alias CoreWeb.Endpoint
  alias Systems.Desktop

  describe "intercept/2" do
    setup do
      user = Factories.insert!(:member)
      topic = "signal:#{Systems.Desktop.Page}:#{user.id}"
      Endpoint.subscribe(topic)
      {:ok, user: user, topic: topic}
    end

    test "{:next_action, :created} broadcasts a Desktop.Page observation",
         %{user: user, topic: topic} do
      :ok =
        Desktop.Switch.intercept(
          {:next_action, :created},
          %{user: user, from_pid: self()}
        )

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end

    test "{:next_action, :cleared} broadcasts a Desktop.Page observation",
         %{user: user, topic: topic} do
      :ok =
        Desktop.Switch.intercept(
          {:next_action, :cleared},
          %{user: user, from_pid: self()}
        )

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end
  end
end
