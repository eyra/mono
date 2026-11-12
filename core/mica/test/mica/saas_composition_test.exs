defmodule Mica.SaaSCompositionTest do
  # put_composition/1 changes the composition for every process.
  use ExUnit.Case, async: false

  alias Mica.SaaS

  defmodule Notifier do
    def notify_events, do: [composition_test_event: [channels: [:email]]]
  end

  defmodule Page do
  end

  setup do
    previous = SaaS.put_composition(%{})
    on_exit(fn -> SaaS.put_composition(previous) end)
  end

  test "the readers take the parts that a test puts" do
    SaaS.put_composition(desktop_sections: [], signal_handlers: [Frameworks.Signal.TestRecorder])

    assert SaaS.desktop_sections() == []
    assert SaaS.signal_handlers() == [Frameworks.Signal.TestRecorder]
  end

  test "returns the composition it replaced" do
    handlers = SaaS.signal_handlers()
    previous = SaaS.put_composition(signal_handlers: [])

    SaaS.put_composition(previous)
    assert SaaS.signal_handlers() == handlers
  end

  test "the notify event types follow the notifiers a test puts" do
    SaaS.put_composition(notifiers: [Notifier])

    assert SaaS.notify_events() == %{"composition_test_event" => [:email]}
    assert Systems.Notify.EventType.channels_for(:composition_test_event) == [:email]
  end

  test "the permission map follows the grants a test puts" do
    SaaS.put_composition(grants: SaaS.grants() ++ [{Page, [:member]}])

    assert Mica.Authorization.permission_map()
           |> Frameworks.GreenLight.PermissionMap.allowed?(
             Frameworks.GreenLight.Permissions.access_permission(Page),
             [:member]
           )
  end

  test "a part the composition doesn't have raises" do
    assert_raise ArgumentError, "not a part of the composition: [:handlers]", fn ->
      SaaS.put_composition(handlers: [])
    end
  end
end
