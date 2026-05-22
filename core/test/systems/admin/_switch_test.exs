defmodule Systems.Admin.SwitchTest do
  @moduledoc """
  Regression coverage for FX#9905887344 — Admin.OrgView shows the same
  AddDomainMembers NextAction banner as Desktop and must rebuild its
  view model when NextActions change so the banner disappears live.
  """
  use Core.DataCase, async: false

  alias CoreWeb.Endpoint
  alias Systems.Admin

  describe "intercept/2" do
    setup do
      topic = "signal:#{Systems.Admin.OrgView}:singleton"
      Endpoint.subscribe(topic)
      {:ok, topic: topic}
    end

    test "{:next_action, :created} broadcasts an Admin.OrgView observation",
         %{topic: topic} do
      :ok = Admin.Switch.intercept({:next_action, :created}, %{from_pid: self()})

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end

    test "{:next_action, :cleared} broadcasts an Admin.OrgView observation",
         %{topic: topic} do
      :ok = Admin.Switch.intercept({:next_action, :cleared}, %{from_pid: self()})

      assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: "observation"}
    end
  end
end
