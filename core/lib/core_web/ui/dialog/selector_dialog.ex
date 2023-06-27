defmodule CoreWeb.UI.SelectorDialog do
  use CoreWeb, :live_component

  import CoreWeb.UI.Dialog
  alias Frameworks.Pixel.Selector

  @impl true
  def update(%{active_item_id: active_item_id, selector_id: :type}, socket) do
    active_item_id =
      case active_item_id do
        nil -> nil
        item when is_binary(item) -> String.to_atom(item)
        _ -> active_item_id
      end

    {
      :ok,
      socket
      |> assign(active_item_id: active_item_id)
    }
  end

  @impl true
  def update(
        %{
          id: id,
          title: title,
          text: text,
          items: items,
          ok_button_text: ok_button_text,
          cancel_button_text: cancel_button_text,
          target: target
        },
        socket
      ) do
    items = prepare(items)
    active_item_id = active_id(items)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        text: text,
        active_item_id: active_item_id,
        items: items,
        ok_button_text: ok_button_text,
        cancel_button_text: cancel_button_text,
        target: target
      )
    }
  end

  defp prepare(nil), do: []
  defp prepare([]), do: []

  defp prepare(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      Map.replace(item, :active, index == 0)
    end)
  end

  defp active_id([]), do: nil

  defp active_id(items) do
    Enum.find_value(
      items,
      &if &1.active do
        &1.id
      end
    )
  end

  @impl true
  def handle_event(
        "ok",
        _params,
        %{assigns: %{active_item_id: active_item_id, target: target}} = socket
      ) do
    update_target(target, %{selector: :ok, selected: active_item_id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _params, %{assigns: %{target: target}} = socket) do
    update_target(target, %{selector: :cancel})
    {:noreply, socket}
  end

  def buttons(%{ok_button_text: ok, cancel_button_text: cancel}, target) do
    [
      %{
        action: %{type: :send, event: "ok", target: target},
        face: %{type: :primary, label: ok}
      },
      %{
        action: %{type: :send, event: "cancel", target: target},
        face: %{type: :label, label: cancel}
      }
    ]
  end

  attr(:title, :string, required: true)
  attr(:text, :string, required: true)
  attr(:items, :list, required: true)
  attr(:ok_button_text, :string, required: true)
  attr(:cancel_button_text, :string, required: true)
  attr(:target, :any, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <.dialog {%{title: @title, text: @text, buttons: buttons(assigns, @myself)}}>
      <.live_component
        module={Selector}
        id={:type}
        items={@items}
        type={:radio}
        parent={%{type: __MODULE__, id: @id}}
      />
    </.dialog>
    """
  end
end
