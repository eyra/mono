defmodule LiveNest.InfiniteLoopTest do
  @moduledoc """
  Test that demonstrates and prevents infinite event loops.

  The issue: When a routed LiveView receives an event it doesn't handle,
  the fallback consume_event returns {:continue, socket}. This causes
  the event to be republished. For routed LiveViews, publish_event sends
  to self(), creating an infinite loop.
  """

  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  # Minimal routed LiveView that doesn't handle :unhandled_event
  defmodule UnhandledEventPage do
    use CoreWeb, :routed_live_view

    @impl true
    def mount(_params, _session, socket) do
      {:ok, socket |> assign(triggered: false, modal: nil)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="test-page">
        <span id="triggered"><%= @triggered %></span>
        <button id="trigger-event" phx-click="trigger_unhandled_event">Trigger</button>
      </div>
      """
    end

    @impl true
    def handle_event("trigger_unhandled_event", _, socket) do
      {:noreply, socket |> assign(triggered: true) |> publish_event(:unhandled_event)}
    end

    # Note: No consume_event/2 for :unhandled_event
  end

  describe "infinite loop prevention" do
    test "unhandled event on routed LiveView should not cause infinite loop", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> Map.put(:request_path, "")
        |> live_isolated(UnhandledEventPage)

      lv_pid = view.pid
      {:reductions, initial_reductions} = Process.info(lv_pid, :reductions)

      view |> element("#trigger-event") |> render_click()

      Process.sleep(100)

      {:reductions, final_reductions} = Process.info(lv_pid, :reductions)
      reductions_diff = final_reductions - initial_reductions

      max_allowed_reductions = 1_000_000

      assert reductions_diff < max_allowed_reductions,
             "Process used #{reductions_diff} reductions in 100ms " <>
               "(threshold: #{max_allowed_reductions}). " <>
               "This indicates an infinite event loop."
    end
  end
end
