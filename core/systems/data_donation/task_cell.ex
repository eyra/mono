defmodule Systems.DataDonation.TaskCell do
  use CoreWeb, :live_component

  alias Systems.{
    DataDonation
  }

  @impl true
  def update(
        %{id: id, task: task, parent: parent, relative_position: relative_position},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        task: task,
        parent: parent,
        relative_position: relative_position
      )
      |> update_task_form()
      |> update_special_form()
      |> update_title()
      |> update_status()
      |> update_buttons()
    }
  end

  @impl true
  def handle_event(action, _params, %{assigns: %{parent: parent, task: task}} = socket) do
    update_target(parent, %{module: __MODULE__, action: action, task: task})
    {:noreply, socket}
  end

  defp update_task_form(%{assigns: %{id: id, task: task}} = socket) do
    task_form = %{
      id: "#{id}_task_form",
      module: DataDonation.TaskForm,
      entity: task
    }

    socket |> assign(task_form: task_form)
  end

  defp update_special_form(%{assigns: %{task: task}} = socket) do
    special_form = special_form(task)
    socket |> assign(special_form: special_form)
  end

  defp special_form(%{request_task: %{id: id} = entity}),
    do: %{
      id: "#{id}_request_form",
      module: DataDonation.DocumentTaskForm,
      entity: entity
    }

  defp special_form(%{download_task: %{id: id} = entity}),
    do: %{
      id: "#{id}_request_form",
      module: DataDonation.DocumentTaskForm,
      entity: entity
    }

  defp special_form(_), do: nil

  defp update_status(%{assigns: %{task: task}} = socket) do
    status = DataDonation.TaskModel.status(task)
    assign(socket, status: status)
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
      action: %{type: :fake},
      face: %{
        type: :label,
        label: dgettext("eyra-ui", "collapse.button"),
        text_color: "text-primary",
        icon: :chevron_up
      }
    }

    expand_button = %{
      action: %{type: :fake},
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

  defp get_title(%{questionnaire_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.questionnaire.title")

  defp get_title(%{request_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.request.title")

  defp get_title(%{download_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.download.title")

  defp get_title(%{donate_task_id: id}) when not is_nil(id),
    do: dgettext("eyra-data-donation", "task.donate.title")

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="bg-white rounded-md p-6" phx-hook="Cell" >
      <div class="flex flex-row gap-4 items-center mb-8">
        <Text.title3 margin=""><%= @title %></Text.title3>
        <%= if @status == :ready do %>
          <div>
            <img class="h-6 w-6" src="/images/icons/ready.svg" alt="ready">
          </div>
        <% end %>
        <div class="flex-grow" />
        <%= if @relative_position != :bottom do %>
          <Button.dynamic {@down_button}/>
        <% end %>
        <%= if @relative_position != :top do %>
          <Button.dynamic {@up_button}/>
        <% end %>
        <Button.dynamic {@delete_button}/>
      </div>
      <div class="cell-expanded-view">
        <.live_component {@task_form} />
        <%= if @special_form do %>
          <.live_component {@special_form} />
          <.spacing value="XS" />
        <% end %>
        <div class="cell-collapse-button">
          <Button.dynamic {@collapse_button}/>
        </div>
      </div>
      <div class="cell-collapsed-view">
        <div class="cell-expand-button">
          <Button.dynamic {@expand_button}/>
        </div>
      </div>
    </div>
    """
  end
end
