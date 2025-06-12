defmodule Systems.Assignment.CrewWorkView do
  use CoreWeb, :live_component

  require Logger

  alias Systems.Assignment
  alias Systems.Content
  alias Systems.Consent
  alias Systems.Document
  alias Systems.Crew

  def update(
        %{
          work_items: work_items,
          privacy_doc: privacy_doc,
          consent_agreement: consent_agreement,
          context_menu_items: context_menu_items,
          intro_page_ref: intro_page_ref,
          support_page_ref: support_page_ref,
          affiliate: affiliate,
          crew: crew,
          user: user,
          timezone: timezone,
          panel_info: panel_info,
          tester?: tester?
        },
        socket
      ) do
    retry? = Map.get(socket.assigns, :retry?, false)
    finished? = tasks_finished?(work_items)
    user_state_initialized? = Map.get(socket.assigns, :user_state_initialized?, false)

    socket =
      socket
      |> assign(
        work_items: work_items,
        privacy_doc: privacy_doc,
        consent_agreement: consent_agreement,
        context_menu_items: context_menu_items,
        intro_page_ref: intro_page_ref,
        support_page_ref: support_page_ref,
        affiliate: affiliate,
        crew: crew,
        user: user,
        timezone: timezone,
        tester?: tester?,
        panel_info: panel_info,
        retry?: retry?,
        user_state_initialized?: user_state_initialized?,
        user_state_data: nil
      )

    socket =
      if finished? and not retry? do
        socket
        |> compose_child(:finished_view)
        |> compose_child(:context_menu)
      else
        socket
        |> compose_child(:context_menu)
        |> compose_child(:task_view)
      end

    {
      :ok,
      socket
    }
  end

  # Compose

  @impl true
  def compose(:task_view, %{
        work_items: [work_item],
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_data: user_state_data
      })
      when not is_nil(user_state_data) do
    %{
      module: Assignment.CrewTaskSingleView,
      params: %{
        work_item: work_item,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_data: user_state_data
      }
    }
  end

  @impl true
  def compose(:task_view, %{
        work_items: work_items,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_data: user_state_data
      })
      when not is_nil(user_state_data) do
    %{
      module: Assignment.CrewTaskListView,
      params: %{
        work_items: work_items,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_data: user_state_data
      }
    }
  end

  def compose(:task_view, _) do
    nil
  end

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

  def compose(:intro_page, %{intro_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "intro.page.title"),
        page: page
      }
    }
  end

  def compose(:privacy_page, %{privacy_doc: %{ref: ref}}) do
    %{
      module: Document.PDFView,
      params: %{
        key: "privacy_doc_view",
        url: ref,
        title: dgettext("eyra-assignment", "privacy.title")
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

  def compose(:support_page, %{support_page_ref: %{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: dgettext("eyra-assignment", "support.page.title"),
        page: page
      }
    }
  end

  def compose(:finished_view, %{affiliate: affiliate, user: user}) do
    %{
      module: Assignment.FinishedView,
      params: %{
        title: dgettext("eyra-assignment", "finished_view.title"),
        user: user,
        affiliate: affiliate
      }
    }
  end

  # Events

  def handle_event("retry", _, socket) do
    {
      :noreply,
      socket
      |> assign(retry?: true)
      |> hide_child(:finished_view)
      |> compose_child(:context_menu)
      |> compose_child(:task_view)
    }
  end

  def handle_event("tool_initialized", _, socket) do
    {
      :noreply,
      socket
      |> send_event(:task_view, "tool_initialized")
    }
  end

  @impl true
  def handle_event("cancel_task", _payload, socket) do
    {
      :noreply,
      socket
      |> send_event(:task_view, "cancel_task")
    }
  end

  @impl true
  def handle_event("feldspar_event", event, socket) do
    {
      :noreply,
      socket
      |> send_event(:task_view, "feldspar_event", event)
    }
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

  def handle_event("complete_task", _, socket) do
    {
      :noreply,
      socket
      |> send_event(:task_view, "complete_task")
    }
  end

  def handle_event("task_completed", _, socket) do
    {
      :noreply,
      socket |> handle_finished_state()
    }
  end

  def handle_event("user_state_initialized", _, socket) do
    {
      :noreply,
      socket
      |> assign(user_state_initialized: true)
      |> compose_child(:task_view)
    }
  end

  def handle_event("user_state_data", _, %{assigns: %{tester?: true}} = socket) do
    # No user state data for testers
    {
      :noreply,
      socket
      |> assign(user_state_data: %{})
    }
  end

  def handle_event("user_state_data", %{"data" => data}, socket) do
    {
      :noreply,
      socket
      |> assign(user_state_data: data)
    }
  end

  defp show_context_menu_item(socket, :privacy) do
    socket
    |> compose_child(:privacy_page)
    |> show_modal(:privacy_page, :page)
  end

  defp show_context_menu_item(socket, :consent) do
    socket
    |> compose_child(:consent_page)
    |> show_modal(:consent_page, :page)
  end

  defp show_context_menu_item(socket, :assignment_information) do
    socket
    |> compose_child(:intro_page)
    |> show_modal(:intro_page, :page)
  end

  defp show_context_menu_item(socket, :assignment_helpdesk) do
    socket
    |> compose_child(:support_page)
    |> show_modal(:support_page, :page)
  end

  defp handle_finished_state(%{assigns: %{retry?: true}} = socket), do: socket

  defp handle_finished_state(%{assigns: %{work_items: work_items}} = socket) do
    if tasks_finished?(work_items) do
      socket |> compose_child(:finished_view)
    else
      socket
    end
  end

  defp tasks_finished?(nil), do: false

  defp tasks_finished?(work_items) do
    task_ids =
      work_items
      |> Enum.reject(fn {_, task} -> task == nil end)
      |> Enum.map(fn {_, task} -> task.id end)

    Crew.Public.tasks_finished?(task_ids)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id="crew_work_view" class="w-full h-full relative" phx-hook="UserStateObserver" data-initialized={@user_state_initialized?}>
        <%= if exists?(@fabric, :finished_view) do %>
          <.child name={:finished_view} fabric={@fabric} />
        <% else %>
          <div class="w-full h-full">
            <.child name={:task_view} fabric={@fabric} />
          </div>
        <% end %>

        <%!-- floating button --%>
        <div class="fixed z-100 right-4 bottom-3">
          <Content.Html.context_menu items={@context_menu_items} />
        </div>
      </div>
    """
  end
end
