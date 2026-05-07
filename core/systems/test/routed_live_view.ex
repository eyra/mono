defmodule Systems.Test.RoutedLiveView do
  @moduledoc """
  Generic routed LiveView for testing purposes.
  Can optionally render embedded child views based on configuration.
  """
  use CoreWeb, :routed_live_view

  import LiveNest.HTML

  alias Systems.Test

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
  on_mount({Systems.Observatory.LiveHook, __MODULE__})

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    build_model(id)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       user_state: %{},
       received_events: [],
       modal_toolbar_buttons: []
     )}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  def consume_event(%{name: :show_modal, payload: %{modal: modal}}, socket) do
    {:stop, present_modal(socket, modal)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="routed-live-view">
      <h1>{@vm.title}</h1>

      <%= for child_element <- @vm.child_elements do %>
        <.element {Map.from_struct(child_element)} socket={@socket} />
      <% end %>

      <div data-testid="received-events">
        <%= for event <- @received_events do %>
          <div class="event">{inspect(event)}</div>
        <% end %>
      </div>
    </div>

    <ModalView.dynamic modal={@vm.modal} toolbar_buttons={@modal_toolbar_buttons} socket={@socket} />
    """
  end

  defp build_model("simple") do
    %Test.RoutedModel{
      id: :simple,
      title: "Simple Test Page",
      children: []
    }
  end

  defp build_model("with_child") do
    %Test.RoutedModel{
      id: :with_child,
      title: "Routed LiveView Test Page",
      children: [
        %{id: :child1, title: "Child 1", namespace: [:collection, 123], items: [10, 20, 30]}
      ]
    }
  end

  defp build_model("with_children") do
    %Test.RoutedModel{
      id: :with_children,
      title: "Routed LiveView Test Page",
      children: [
        %{id: :child1, title: "Child 1", namespace: [:collection, 123], items: [10, 20, 30]},
        %{id: :child2, title: "Child 2", namespace: [:collection, 456], items: [40, 50]}
      ]
    }
  end

  defp build_model("with_modal") do
    modal =
      LiveNest.Modal.prepare_live_view(
        "test_modal",
        Test.ModalLiveView,
        style: :full,
        session: [
          title: "Test Modal",
          button_configs: [
            %{label: "Back", icon: :back, icon_align: :left, event: :back},
            %{label: "Next", icon: :forward, event: :next}
          ]
        ]
      )

    %Test.RoutedModel{
      id: :with_modal,
      title: "Modal Test Page",
      children: [],
      modal: modal
    }
  end

  defp build_model(id) do
    %Test.RoutedModel{
      id: String.to_atom(id),
      title: "Test Page",
      children: []
    }
  end
end
