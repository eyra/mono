defmodule CoreWeb.UI.SelectorDialog do
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Dialog
  alias Frameworks.Pixel.Selector.Selector

  prop(title, :string, required: true)
  prop(text, :string, required: true)
  prop(items, :list, required: true)
  prop(ok_button_text, :string, required: true)
  prop(cancel_button_text, :string, required: true)
  prop(target, :any, required: true)

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

  @impl true
  def render(assigns) do
    ~F"""
    <Dialog {...%{title: @title, text: @text, buttons: buttons(assigns, @myself)}}>
      <Selector id={:type} items={@items} type={:radio} parent={%{type: __MODULE__, id: @id}} />
    </Dialog>
    """
  end
end

defmodule CoreWeb.UI.SelectorDialog.Example do
  use Surface.Catalogue.Example,
    subject: CoreWeb.UI.SelectorDialog,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Selector Dialog",
    height: "640px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <SelectorDialog
      id={:selector_dialog_example}
      title="Selector dialog title"
      text="Selector dialog text"
      items={Core.Enums.Themes.labels(nil)}
      ok_button_text="Proceed"
      cancel_button_text="Cancel"
      target={self()}
    />
    """
  end

  def handle_info(%{selector: :ok, selected: selected_item}, socket) do
    IO.puts("ok -> #{selected_item}")
    {:noreply, socket}
  end

  def handle_info(%{selector: :cancel}, socket) do
    IO.puts("cancel")
    {:noreply, socket}
  end
end
