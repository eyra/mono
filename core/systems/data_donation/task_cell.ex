defmodule Systems.DataDonation.TaskCell do
  use CoreWeb, :live_component

  alias Systems.{
    DataDonation
  }

  @impl true
  def update(
        %{id: id, entity_id: entity_id, parent: parent, relative_position: relative_position},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity_id: entity_id,
        parent: parent,
        expanded?: false,
        relative_position: relative_position
      )
      |> update_task()
      |> update_task_form()
      |> update_title()
      |> update_buttons()
    }
  end

  @impl true
  def handle_event("collapse", _params, socket) do
    {:noreply, socket |> assign(expanded?: false)}
  end

  @impl true
  def handle_event("expand", _params, socket) do
    {:noreply, socket |> assign(expanded?: true)}
  end

  @impl true
  def handle_event(action, _params, %{assigns: %{parent: parent, task: task}} = socket) do
    update_target(parent, %{module: __MODULE__, action: action, task: task})
    {:noreply, socket}
  end

  defp update_task(%{assigns: %{entity_id: entity_id}} = socket) do
    task = DataDonation.Public.get_task!(entity_id)
    socket |> assign(task: task)
  end

  defp update_task_form(%{assigns: %{id: id, task: task}} = socket) do
    task_form = %{
      id: "#{id}_task_form",
      module: DataDonation.TaskForm,
      entity_id: task.id
    }

    socket |> assign(task_form: task_form)
  end

  defp update_title(%{assigns: %{task: task}} = socket) do
    title = get_title(task)
    assign(socket, title: title)
  end

  defp update_buttons(socket) do
    up_button = %{
      action: %{type: :send, event: "up"},
      face: %{type: :icon, icon: :arrow_up}
    }

    down_button = %{
      action: %{type: :send, event: "down"},
      face: %{type: :icon, icon: :arrow_down}
    }

    delete_button = %{
      action: %{type: :send, event: "delete"},
      face: %{type: :icon, icon: :delete_red}
    }

    collapse_button = %{
      action: %{type: :send, event: "collapse"},
      face: %{
        type: :label,
        label: dgettext("eyra-ui", "collapse.button"),
        text_color: "text-primary",
        icon: :chevron_up
      }
    }

    expand_button = %{
      action: %{type: :send, event: "expand"},
      face: %{
        type: :label,
        label: dgettext("eyra-ui", "expand.button"),
        text_color: "text-primary",
        icon: :chevron_down
      }
    }

    assign(socket,
      up_button: up_button,
      down_button: down_button,
      delete_button: delete_button,
      collapse_button: collapse_button,
      expand_button: expand_button
    )
  end

  defp get_title(%{survey_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.survey.title")

  defp get_title(%{request_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.request.title")

  defp get_title(%{download_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.download.title")

  defp get_title(%{donate_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.donate.title")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-md p-6">
      <div class="flex flex-row gap-4">
        <Text.title3><%= @title %></Text.title3>
        <div class="flex-grow" />
        <%= if @relative_position != :bottom do %>
          <Button.dynamic {@down_button}/>
        <% end %>
        <%= if @relative_position != :top do %>
          <Button.dynamic {@up_button}/>
        <% end %>
        <Button.dynamic {@delete_button}/>
      </div>
      <%= if @expanded? do %>
        <.live_component {@task_form} />
        <Button.dynamic {@collapse_button}/>
      <% else %>
        <Button.dynamic {@expand_button}/>
      <% end %>
    </div>
    """
  end
end
