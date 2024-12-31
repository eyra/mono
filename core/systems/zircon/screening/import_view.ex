defmodule Systems.Zircon.Screening.ImportView do
  use CoreWeb, :live_component

  @impl true
  def update(
        %{tool: tool, timezone: timezone, title: title, content_flags: content_flags},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        timezone: timezone,
        title: title,
        content_flags: content_flags,
        paper_count: 0
      )
      |> compose_child(:import_form)
    }
  end

  @impl true
  def compose(:import_form, %{tool: tool, timezone: timezone}) do
    %{
      module: Systems.Zircon.Screening.ImportForm,
      params: %{
        tool: tool,
        timezone: timezone
      }
    }
  end

  @impl true
  def handle_event("update_paper_count", %{paper_count: paper_count}, socket) do
    {:noreply, assign(socket, paper_count: paper_count)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2>
            <%= @title %>
            <span class="text-primary"><%= @paper_count %></span>
          </Text.title2>
          <.stack fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
