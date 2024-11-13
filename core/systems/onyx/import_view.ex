defmodule Systems.Onyx.ImportView do
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
        papers: []
      )
      |> compose_child(:import_form)
    }
  end

  @impl true
  def compose(:import_form, %{tool: tool, timezone: timezone}) do
    %{
      module: Systems.Onyx.ImportForm,
      params: %{
        tool: tool,
        timezone: timezone
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2>
            <%= @title %>
            <span class="text-primary"><%= Enum.count(@papers) %></span>
          </Text.title2>
          <.stack fabric={@fabric} />
        </Area.content>
      </div>
    """
  end
end
