defmodule Systems.Project.CreatePopup do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Selector

  alias Systems.{
    Project
  }

  # Handle Tool Type Selector Update
  @impl true
  def update(
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

  # Initial Update
  @impl true
  def update(%{id: id, user: user, target: target}, socket) do
    title = dgettext("eyra-project", "create.title")

    {
      :ok,
      socket
      |> assign(id: id, user: user, target: target, title: title)
      |> init_templates()
      |> init_buttons()
    }
  end

  defp init_templates(socket) do
    selected_template = :empty
    template_labels = Project.Templates.labels(selected_template)
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
    {:ok, %{project: %{root: %{id: root_node_id}}}} = create_project(socket, selected_template)
    {:noreply, socket |> redirect_to(root_node_id)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> close()}
  end

  defp close(%{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: :close})
    socket
  end

  defp redirect_to(%{assigns: %{target: target}} = socket, project_id) do
    update_target(target, %{module: __MODULE__, action: %{redirect_to: project_id}})
    socket
  end

  defp create_project(%{assigns: %{user: user}}, template) do
    name = Project.Templates.translate(template)
    Project.Assembly.create(name, user, template)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= @title %></Text.title3>
      <.spacing value="XS" />
      <.live_component
        module={Selector}
        id={:template_selector}
        items={@template_labels}
        type={:radio}
        optional?={false}
        parent={%{type: __MODULE__, id: @id}}
      />

      <.spacing value="M" />
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </div>
    """
  end
end
