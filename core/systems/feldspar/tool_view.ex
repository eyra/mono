defmodule Systems.Feldspar.ToolView do
  use CoreWeb, :live_component

  alias Systems.Feldspar

  @impl true
  def update(_params, %{assigns: %{started: true}} = socket) do
    # Ignore realtime updates if started to prevent app_view from being hidden
    {:ok, socket}
  end

  def update(%{tool: tool, title: title, icon: icon}, socket) do
    description = dgettext("eyra-feldspar", "tool.description")
    loading = Map.get(socket.assigns, :loading, false)

    {
      :ok,
      socket
      |> assign(
        tool: tool,
        title: title,
        description: description,
        icon: icon,
        started: false,
        loading: loading,
        initialized: false
      )
      |> update_button()
      |> compose_child(:app_view)
    }
  end

  def update_button(%{assigns: %{loading: loading}} = socket) do
    button = %{
      action: %{type: :send, event: "start"},
      face: %{
        type: :primary,
        label: dgettext("eyra-feldspar", "tool.button"),
        loading: loading
      }
    }

    assign(socket, button: button)
  end

  @impl true
  def compose(:app_view, %{tool: %{id: id, archive_ref: archive_ref}}) do
    %{
      module: Feldspar.AppView,
      params: %{
        key: "feldspar_tool_#{id}",
        url: archive_ref <> "/index.html",
        locale: Gettext.get_locale(CoreWeb.Gettext)
      }
    }
  end

  def handle_event("start", _, %{assigns: %{initialized: true}} = socket) do
    {
      :noreply,
      socket
      |> assign(started: true)
    }
  end

  def handle_event("start", _, %{assigns: %{initialized: false}} = socket) do
    {
      :noreply,
      socket
      |> assign(
        started: true,
        loading: true
      )
      |> update_button()
    }
  end

  def handle_event("tool_initialized", _, socket) do
    {
      :noreply,
      socket
      |> assign(initialized: true, loading: false)
      |> update_button()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="w-full h-full">
        <div class={"w-full h-full pt-2 sm:pt-4 #{if @started and @initialized, do: "block", else: "hidden"}"}>
          <.child name={:app_view} fabric={@fabric} />
        </div>
        <div class={"w-full h-full #{if @started and @initialized, do: "hidden", else: "block"}"}>
          <Align.horizontal_center>
          <Area.sheet>
            <div class="flex flex-col gap-8 items-center px-8">
              <div>
                <%= if @icon do %>
                  <img class="w-24 h-24" src={~p"/images/icons/#{"#{@icon}_square.svg"}"} onerror="this.src='/images/icons/placeholder_square.svg';" alt={@icon}>
                <% end %>
              </div>
              <Text.title2 align="text-center" margin=""><%= @title %></Text.title2>
              <Text.body align="text-center"><%= @description %></Text.body>
              <.wrap>
                <Button.dynamic {@button} />
              </.wrap>
            </div>
          </Area.sheet>
          </Align.horizontal_center>
        </div>
      </div>
    """
  end
end
