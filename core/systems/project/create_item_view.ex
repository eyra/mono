defmodule Systems.Project.CreateItemView do
  use CoreWeb, :live_component

  import CoreWeb.UI.Dialog

  alias Frameworks.Pixel.Selector

  alias Systems.Project

  # Initial Update
  @impl true
  def update(%{id: id, node: node, user: user}, socket) do
    title = dgettext("eyra-project", "create.item.title")

    {
      :ok,
      socket
      |> assign(id: id, node: node, user: user, title: title)
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
      |> Enum.filter(&include?/1)

    template_labels = Project.ItemTemplates.labels(selected_template, filter)
    socket |> assign(template_labels: template_labels, selected_template: selected_template)
  end

  defp include?(:questionnaire), do: feature_enabled?(:panl)
  defp include?(:paper_screening), do: feature_enabled?(:onyx)
  defp include?(_), do: true

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :send, event: "create_item", target: myself},
          face: %{
            type: :primary,
            label: dgettext("eyra-project", "create_item_popup.create.button")
          }
        }
      ]
    )
  end

  @impl true
  def handle_event(
        "create_item",
        _,
        %{assigns: %{selected_template: selected_template}} = socket
      ) do
    create_item(socket, selected_template)

    {:noreply, socket |> send_event(:parent, "saved")}
  end

  @impl true
  def handle_event(
        "active_item_id",
        %{active_item_id: active_item_id, source: %{name: :template_selector}},
        %{assigns: %{template_labels: template_labels}} = socket
      ) do
    %{id: selected_template} = Enum.find(template_labels, &(&1.id == active_item_id))

    {
      :noreply,
      socket
      |> assign(selected_template: selected_template)
    }
  end

  defp create_item(%{assigns: %{node: node, user: user}}, template) do
    default_name = Project.ItemTemplates.translate(template)
    name = Project.Public.new_item_name(node, default_name)
    Project.Assembly.create_item(template, name, node, user)
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
