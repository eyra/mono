defmodule Systems.Workflow.ItemCell do
  use CoreWeb, :live_component

  alias Frameworks.Concept
  alias Systems.Workflow

  @impl true
  def update(
        %{
          id: id,
          type: type,
          item: item,
          relative_position: relative_position,
          user: user,
          uri_origin: uri_origin,
          ordering_enabled?: ordering_enabled?,
          timezone: timezone
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        type: type,
        item: item,
        relative_position: relative_position,
        user: user,
        uri_origin: uri_origin,
        ordering_enabled?: ordering_enabled?,
        timezone: timezone
      )
      |> update_item_view()
      |> update_item_form()
      |> compose_child(:tool_form)
      |> update_ready()
      |> update_buttons()
    }
  end

  @impl true
  def compose(:tool_form, %{
        item: %{id: item_id, tool_ref: tool_ref, title: title},
        user: user,
        uri_origin: uri_origin,
        timezone: timezone
      }) do
    tool = Workflow.ToolRefModel.flatten(tool_ref)
    tool_form_module = Workflow.ToolRefModel.form(tool_ref)

    callback_path = ~p"/assignment/callback/#{item_id}"
    callback_url = uri_origin <> callback_path

    %{
      module: tool_form_module,
      params: %{
        entity: tool,
        title: title,
        timezone: timezone,
        callback_url: callback_url,
        user: user
      }
    }
  end

  @impl true
  def handle_event(action, _params, %{assigns: %{item: item}} = socket) do
    {:noreply, socket |> send_event(:parent, action, %{item: item})}
  end

  defp update_item_view(%{assigns: %{item: %{title: _title}}} = socket) do
    item_view = %{
      function: &Workflow.HTML.collapsed/1,
      props: %{
        # title: title,
        inner_block: nil
      }
    }

    socket |> assign(item_view: item_view)
  end

  defp update_item_form(%{assigns: %{id: id, item: %{tool_ref: tool_ref} = item}} = socket) do
    group_enabled? =
      Workflow.ToolRefModel.flatten(tool_ref)
      |> Concept.ToolModel.group_enabled?()

    item_form = %{
      id: "#{id}_item_form",
      module: Workflow.ItemForm,
      entity: item,
      group_enabled?: group_enabled?
    }

    socket |> assign(item_form: item_form)
  end

  defp update_ready(%{assigns: %{item: item}} = socket) do
    ready? = Workflow.ItemModel.ready?(item)
    assign(socket, ready?: ready?)
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

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="bg-white rounded-md p-6" phx-hook="Cell" >
      <div class="flex flex-row gap-4 items-center mb-8">
        <Text.title3 margin=""><%= @type %></Text.title3>
        <%= if @ready? do %>
          <div>
            <img class="h-6 w-6" src={~p"/images/icons/ready.svg"} alt="ready">
          </div>
        <% end %>
        <div class="flex-grow" />
        <%= if @ordering_enabled? do %>
          <%= if @relative_position != :bottom do %>
            <Button.dynamic {@down_button}/>
          <% end %>
          <%= if @relative_position != :top do %>
            <Button.dynamic {@up_button}/>
          <% end %>
        <% end %>
        <Button.dynamic {@delete_button}/>
      </div>
      <div class="cell-expanded-view">
        <.live_component {@item_form} />
          <.child name={:tool_form} fabric={@fabric} >
            <:footer>
              <.spacing value="XS" />
            </:footer>
         </.child>
        <div class="cell-collapse-button">
          <Button.dynamic {@collapse_button}/>
        </div>
      </div>
      <div class="cell-collapsed-view">
        <.function_component {@item_view} />
        <div class="cell-expand-button">
          <Button.dynamic {@expand_button}/>
        </div>
      </div>
    </div>
    """
  end
end
