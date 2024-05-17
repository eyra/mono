defmodule Systems.Project.CreateItemPopup do
  use CoreWeb, :live_component

  import CoreWeb.UI.Dialog

  alias Frameworks.Pixel.Selector

  alias Systems.{
    Project
  }

  # Initial Update
  @impl true
  def update(%{id: id, node: node}, socket) do
    title = dgettext("eyra-project", "create.item.title")

    {
      :ok,
      socket
      |> assign(id: id, node: node, title: title)
      |> init_templates()
      |> compose_child(:template_selector)
      |> init_buttons()
    }
  end

  @impl true
  def compose(:template_selector, %{template_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :radio,
        optional?: false
      }
    }
  end

  defp init_templates(socket) do
    selected_template = :empty

    filter =
      Systems.Project.ItemTemplates.values()
      |> Enum.reject(&(&1 == :leaderboard))

    template_labels = Project.ItemTemplates.labels(selected_template, filter)
    socket |> assign(template_labels: template_labels, selected_template: selected_template)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :send, event: "proceed", target: myself},
          face: %{
            type: :primary,
            label: dgettext("eyra-project", "create.proceed.button")
          }
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event(
        "proceed",
        _,
        %{assigns: %{selected_template: selected_template}} = socket
      ) do
    create_item(socket, selected_template)

    {:noreply, socket |> finish()}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> finish()}
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, selector_id: :template_selector},
        %{assigns: %{template_labels: template_labels}} = socket
      ) do
    %{id: selected_template} = Enum.find(template_labels, &(&1.id == active_item_id))

    {
      :ok,
      socket
      |> assign(selected_template: selected_template)
    }
  end

  defp finish(socket) do
    socket |> send_event(:parent, "finish")
  end

  defp create_item(%{assigns: %{node: node}}, template) do
    name = Project.ItemTemplates.translate(template)
    Project.Assembly.create_item(template, name, node)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.dialog {%{title: @title, buttons: @buttons}}>
        <.child name={:template_selector} fabric={@fabric} />
      </.dialog>
    </div>
    """
  end
end
