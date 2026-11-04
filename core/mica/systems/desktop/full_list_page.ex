defmodule Systems.Desktop.FullListPage do
  @moduledoc "A full list supplied by a registered Desktop section, with the same recipient rules and content renderer."
  use Systems.Content.Composer, :live_workspace

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}}), do: user

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= @vm.title %></Text.title2>
        <Margin.y id={:title2_bottom} />
        <div id={"#{@vm.id}-list"}>
          <%= @vm.section.render(%{vm: @vm.content}) %>
        </div>
      </Area.content>
    </.live_workspace>
    """
  end
end
