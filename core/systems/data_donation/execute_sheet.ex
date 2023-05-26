defmodule Systems.DataDonation.ExecuteSheet do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Text

  @impl true
  def update(%{id: id, props: %{script: script, platform: platform}}, socket) do
    {:ok, assign(socket, id: id, script: script, platform: platform)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.sheet>
        <Text.title1><%= dgettext("eyra-data-donation", "extract.data.title") %></Text.title1>
        <code class="hidden"><%= @script %></code>
        <div id="prompt" />

        <div id="spinner" class="flex flex-row items-center gap-4">
          <Text.body_medium><%= dgettext("eyra-data-donation", "execute.spinner") %></Text.body_medium>
          <div class="w-8 h-8">
            <img src="/images/icons/spinner.svg">
          </div>
        </div>
      </Area.sheet>
      </Area.content>
    </div>
    """
  end
end
