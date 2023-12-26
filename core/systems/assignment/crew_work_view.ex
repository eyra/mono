defmodule Systems.Assignment.CrewWorkView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  import Frameworks.Pixel.Line

  require Logger

  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Project,
    Content,
    Consent
  }

  def update(
        %{
          work_items: work_items,
          consent_agreement: consent_agreement,
          context_menu_items: context_menu_items,
          intro_page_ref: intro_page_ref,
          support_page_ref: support_page_ref,
          crew: crew,
          user: user,
          panel_info: panel_info
        },
        socket
      ) do
    tool_started = Map.get(socket.assigns, :tool_started, false)
    tool_initialized = Map.get(socket.assigns, :tool_initialized, false)

    {
      :ok,
      socket
      |> assign(
        work_items: work_items,
        consent_agreement: consent_agreement,
        context_menu_items: context_menu_items,
        intro_page_ref: intro_page_ref,
        support_page_ref: support_page_ref,
        crew: crew,
        user: user,
        panel_info: panel_info,
        tool_started: tool_started,
        tool_initialized: tool_initialized
      )
      |> update_selected_item_id()
      |> update_selected_item()
      |> compose_child(:work_list_view)
      |> compose_child(:start_view)
      |> compose_child(:context_menu)
      |> update_tool_ref_view()
      |> update_child(:finished_view)
    }
  end

  defp tool_visible?(%{assigns: assigns} = _socket) do
    tool_visible?(assigns)
  end

  defp tool_visible?(%{tool_started: tool_started, tool_initialized: tool_initialized}) do
    tool_started and tool_initialized
  end

  defp update_tool_ref_view(%{assigns: %{selected_item_id: selected_item_id}} = socket) do
    case Fabric.get_child(socket, :tool_ref_view) do
      %{params: %{work_item: {%{id: id}, _}}} when id == selected_item_id ->
        socket

      _ ->
        compose_child(socket, :tool_ref_view)
    end
  end

  defp update_selected_item_id(
         %{assigns: %{work_items: work_items, selected_item_id: selected_item_id}} = socket
       )
       when not is_nil(selected_item_id) do
    if Enum.find(work_items, fn {%{id: id}, _} -> id == selected_item_id end) do
      socket
    else
      socket
      |> assign(selected_item_id: nil)
      |> update_selected_item_id()
    end
  end

  defp update_selected_item_id(%{assigns: %{work_items: []}} = socket) do
    socket |> assign(selected_item_id: nil)
  end

  defp update_selected_item_id(%{assigns: %{work_items: work_items}} = socket) do
    {%{id: selected_item_id}, _} =
      Enum.find(work_items, List.first(work_items), fn {_, %{status: status}} ->
        status == :pending
      end)

    socket |> assign(selected_item_id: selected_item_id)
  end

  defp update_selected_item(
         %{assigns: %{selected_item_id: selected_item_id, work_items: work_items}} = socket
       ) do
    selected_item = Enum.find(work_items, fn {%{id: id}, _} -> id == selected_item_id end)

    socket |> assign(selected_item: selected_item)
  end

  # Compose

  @impl true
  def compose(:start_view, %{
        selected_item: selected_item,
        tool_started: tool_started,
        tool_initialized: tool_initialized
      })
      when not is_nil(selected_item) do
    %{
      module: Assignment.StartView,
      params: %{
        work_item: selected_item,
        loading: tool_started and not tool_initialized
      }
    }
  end

  @impl true
  def compose(:start_view, _assigns), do: nil

  @impl true
  def compose(:work_list_view, %{
        work_items: [_one, _two | _] = work_items,
        selected_item_id: selected_item_id
      })
      when not is_nil(selected_item_id) do
    work_list = %{
      items: Enum.map(work_items, &map_item/1),
      selected_item_id: selected_item_id
    }

    %{module: Workflow.WorkListView, params: %{work_list: work_list}}
  end

  @impl true
  def compose(:work_list_view, _assigns), do: nil

  @impl true
  def compose(
        :tool_ref_view,
        %{selected_item: {%{title: title, tool_ref: tool_ref}, task}} = assigns
      ) do
    %{
      module: Project.ToolRefView,
      params: %{title: title, tool_ref: tool_ref, task: task, visible: tool_visible?(assigns)}
    }
  end

  @impl true
  def compose(:tool_ref_view, _assigns), do: nil

  def compose(:context_menu, %{context_menu_items: []}) do
    nil
  end

  def compose(:context_menu, %{context_menu_items: context_menu_items}) do
    %{
      module: Content.ContextMenu,
      params: %{
        items: context_menu_items
      }
    }
  end

  def compose(:consent_page, %{consent_agreement: consent_agreement, user: user}) do
    %{
      module: Consent.SignatureView,
      params: %{
        title: dgettext("eyra-consent", "signature.view.title"),
        signature: Consent.Public.get_signature(consent_agreement, user)
      }
    }
  end

  def compose(:intro_page, %{intro_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "intro.page.title"),
        page: page
      }
    }
  end

  def compose(:support_page, %{support_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "support.page.title"),
        page: page
      }
    }
  end

  def compose(:finished_view, _) do
    %{
      module: Assignment.FinishedView,
      params: %{
        title: dgettext("eyra-assignment", "finished_view.title")
      }
    }
  end

  # Events

  def handle_event("tool_initialized", _, socket) do
    {
      :noreply,
      socket
      |> assign(tool_initialized: true)
    }
  end

  @impl true
  def handle_event("complete_task", _, socket) do
    {
      :noreply,
      socket
      |> handle_complete_task()
    }
  end

  @impl true
  def handle_event(
        "work_item_selected",
        %{"item" => item_id},
        socket
      ) do
    item_id = String.to_integer(item_id)

    {
      :noreply,
      socket
      |> assign(
        tool_initialized: false,
        tool_started: false,
        selected_item_id: item_id
      )
      |> update_selected_item()
      |> compose_child(:start_view)
      |> update_child(:work_list_view)
      |> compose_child(:tool_ref_view)
    }
  end

  @impl true
  def handle_event("start", _, %{assigns: %{selected_item: {_, task}}} = socket) do
    {
      :noreply,
      socket
      |> assign(tool_started: true)
      |> update_child(:tool_ref_view)
      |> lock_task(task)
    }
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {
      :noreply,
      socket |> handle_feldspar_event(event)
    }
  end

  @impl true
  def handle_event("show", %{page: :consent}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:consent_page)
      |> show_modal(:consent_page, :page)
    }
  end

  @impl true
  def handle_event("show", %{page: :assignment_intro}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:intro_page)
      |> show_modal(:intro_page, :page)
    }
  end

  @impl true
  def handle_event("show", %{page: :assignment_support}, socket) do
    {
      :noreply,
      socket
      |> compose_child(:support_page)
      |> show_modal(:support_page, :page)
    }
  end

  @impl true
  def handle_event("close", %{source: %{name: :consent_page}}, socket) do
    {:noreply, socket |> hide_popup(:consent_page)}
  end

  # Private

  defp handle_feldspar_event(
         socket,
         %{
           "__type__" => "CommandSystemExit",
           "code" => code,
           "info" => info
         }
       ) do
    if code == 0 do
      handle_complete_task(socket)
    else
      Frameworks.Pixel.Flash.put_info(
        socket,
        "Application stopped unexpectedly [#{code}]: #{info}"
      )
    end
  end

  defp handle_feldspar_event(socket, %{
         "__type__" => "CommandSystemDonate",
         "key" => key,
         "json_string" => json_string
       }) do
    socket
    |> send_event(:parent, "store", %{key: key, data: json_string})
    |> Frameworks.Pixel.Flash.put_info("Donated")
  end

  defp handle_feldspar_event(socket, %{
         "__type__" => "CommandSystemEvent",
         "name" => "initialized"
       }) do
    socket
    |> assign(tool_initialized: true)
  end

  defp handle_feldspar_event(socket, %{"__type__" => type}) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event " <> type)
  end

  defp handle_feldspar_event(socket, _) do
    socket |> Frameworks.Pixel.Flash.put_error("Unsupported event")
  end

  defp handle_complete_task(%{assigns: %{selected_item: {_, task}}} = socket) do
    {:ok, %{crew_task: updated_task}} = Crew.Public.activate_task(task)

    socket
    |> update_task(updated_task)
    |> reset_selection()
    |> handle_finished_state()
  end

  defp update_task(%{assigns: %{work_items: work_items}} = socket, updated_task) do
    work_items =
      Enum.map(work_items, fn {item, task} ->
        if task.id == updated_task.id do
          {item, updated_task}
        else
          {item, task}
        end
      end)

    assign(socket, work_items: work_items)
  end

  defp reset_selection(%{assigns: %{work_items: work_items}} = socket)
       when length(work_items) <= 1 do
    socket
  end

  defp reset_selection(socket) do
    socket
    |> assign(
      tool_started: false,
      tool_initialized: false,
      selected_item_id: nil
    )
    |> update_selected_item_id()
    |> update_selected_item()
    |> compose_child(:work_list_view)
    |> compose_child(:start_view)
    |> hide_child(:tool_ref_view)
  end

  defp handle_finished_state(%{assigns: %{panel_info: %{embedded?: true}}} = socket) do
    # Dont show finished view when embedded in external panel UI
    socket
  end

  defp handle_finished_state(%{assigns: %{work_items: work_items}} = socket) do
    task_ids = Enum.map(work_items, fn {_, task} -> task.id end)

    if Crew.Public.tasks_finised?(task_ids) do
      socket
      |> compose_child(:finished_view)
      |> show_modal(:finished_view, :sheet)
    else
      socket
    end
  end

  defp map_item({%{id: id, title: title, group: group}, task}) do
    %{id: id, title: title, icon: group, status: task_status(task)}
  end

  defp task_status(%{status: status}), do: status
  defp task_status(_), do: :pending

  defp lock_task(socket, task) do
    Crew.Public.lock_task(task)
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full flex flex-row">
        <%= if exists?(@fabric, :tool_ref_view) do %>
          <div class={"w-full h-full #{ if tool_visible?(assigns) do "block" else "hidden" end }"}>
            <.child name={:tool_ref_view} fabric={@fabric} />
          </div>
        <% end %>
        <%= if not tool_visible?(assigns) do %>
          <%= if exists?(@fabric, :work_list_view) do %>
            <div class="w-left-column flex flex-col py-6 gap-6">
              <div class="px-6">
                <Text.title2 margin=""><%= dgettext("eyra-assignment", "work.list.title") %></Text.title2>
              </div>
              <div>
                <.line />
              </div>
              <div class="flex-grow">
                <div class="px-6 h-full overflow-y-scroll">
                  <.child name={:work_list_view} fabric={@fabric} />
                </div>
              </div>
            </div>
            <div class="border-l border-grey4">
            </div>
          <% end %>
          <div class="h-full w-full">
            <.child name={:start_view} fabric={@fabric} />
          </div>
        <% end %>

        <%!-- floating button --%>
        <.child name={:context_menu} fabric={@fabric} />
      </div>
    """
  end
end
