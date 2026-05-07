defmodule Systems.Assignment.CrewWorkView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes

  require Logger

  alias Systems.Assignment
  alias Systems.Consent
  alias Systems.Content
  alias Systems.Document

  def dependencies(), do: [:assignment_id, :current_user, :panel_info, :timezone, :user_state]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    # Only fetch data needed for routing decision and context menu
    # Child views (CrewTaskListView/CrewTaskSingleView) fetch their own assignment data
    Assignment.Public.get!(assignment_id, [
      :privacy_doc,
      :consent_agreement,
      page_refs: [:page],
      workflow: [:items]
    ])
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  # Events

  @impl true
  def handle_event(
        "tool_initialized",
        _,
        %{assigns: %{vm: %{task_view: %{module: module}}}} = socket
      ) do
    # Forward to task_view component
    send_update(module, id: :task_view, tool_initialized: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "cancel_task",
        _payload,
        %{assigns: %{vm: %{task_view: %{module: module}}}} = socket
      ) do
    # Forward to task_view component
    send_update(module, id: :task_view, cancel_task: true)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "feldspar_event",
        event,
        %{assigns: %{vm: %{task_view: %{module: module}}}} = socket
      ) do
    # Forward to task_view component
    send_update(module, id: :task_view, feldspar_event: event)
    {:noreply, socket}
  end

  @impl true
  def handle_event("context_menu_item_click", %{"item" => item}, socket) do
    item = String.to_existing_atom(item)

    {
      :noreply,
      socket
      |> show_context_menu_item(item)
    }
  end

  @impl true
  def handle_event("task_completed", _, socket) do
    # Notify parent (CrewPage) that task was completed so it can recalculate the view
    {:noreply, socket |> publish_event(:task_completed)}
  end

  defp show_context_menu_item(socket, :privacy) do
    %{assigns: %{vm: %{privacy_doc: %{ref: ref}}}} = socket

    modal =
      LiveNest.Modal.prepare_live_component(
        "privacy_page",
        Document.PDFView,
        params: [
          key: "privacy_doc_view",
          url: ref
        ],
        title: dgettext("eyra-assignment", "privacy.title"),
        style: :page
      )

    socket |> present_modal(modal)
  end

  defp show_context_menu_item(socket, :consent) do
    %{assigns: %{vm: %{consent_agreement: consent_agreement, user: user}}} = socket

    modal =
      LiveNest.Modal.prepare_live_component(
        "consent_page",
        Consent.SignatureView,
        params: [
          title: dgettext("eyra-consent", "signature.view.title"),
          signature: Consent.Public.get_signature(consent_agreement, user)
        ],
        style: :page
      )

    socket |> present_modal(modal)
  end

  defp show_context_menu_item(socket, :assignment_information) do
    %{assigns: %{vm: %{intro_page_ref: %{page: page}}}} = socket

    modal =
      LiveNest.Modal.prepare_live_component(
        "intro_page",
        Content.PageView,
        params: [
          title: dgettext("eyra-assignment", "intro.page.title"),
          page: page
        ],
        style: :page
      )

    socket |> present_modal(modal)
  end

  defp show_context_menu_item(socket, :assignment_helpdesk) do
    %{assigns: %{vm: %{support_page_ref: %{page: page}}}} = socket

    modal =
      LiveNest.Modal.prepare_live_component(
        "support_page",
        Content.PageView,
        params: [
          title: dgettext("eyra-assignment", "support.page.title"),
          page: page
        ],
        style: :page
      )

    socket |> present_modal(modal)
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id="crew_work_view" class="w-full h-full flex flex-col relative">
        <div class="w-full flex-1">
          <%= if @vm.task_view do %>
            <.element {Map.from_struct(@vm.task_view)} socket={@socket} />
          <% end %>
        </div>

        <%!-- floating button --%>
        <div class="fixed z-100 right-4 bottom-3">
          <Content.Html.context_menu items={@vm.context_menu_items} />
        </div>
      </div>
    """
  end
end
