defmodule Systems.Graphite.LeaderboardScoreHTML do
  use CoreWeb, :html

  attr(:scores, :list, required: true)

  def table(assigns) do
    head_cells = [
      dgettext("eyra-graphite", "leaderboard.position.label"),
      dgettext("eyra-graphite", "leaderboard.team.label"),
      dgettext("eyra-graphite", "leaderboard.method.label"),
      dgettext("eyra-graphite", "leaderboard.github.label"),
      dgettext("eyra-graphite", "leaderboard.score.label")
    ]

    layout = [
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :href, width: "w-28", align: "text-center"},
      %{type: :text, width: "w-24", align: "text-right"}
    ]

    assigns = assign(assigns, %{head_cells: head_cells, layout: layout})

    ~H"""
    <div class="overflow-hidden border-2 border-grey4 rounded-lg">
      <div class="w-full border-spacing-0">
        <div class="h-12">
          <.row top={true} cells={@head_cells} layout={@layout}/>
        </div>
        <%= for {%{team: team, description: description, url: url, value: value}, index} <- Enum.with_index(@scores) do %>
          <.row
            bottom={index == Enum.count(@scores)-1}
            cells={["#{index+1}.", team, description, url, value]}
            layout={@layout}
          />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:cells, :list, required: true)
  attr(:layout, :list, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)

  def row(assigns) do
    ~H"""
    <div class="h-12 flex flex-row ">
      <%= for {cell, index} <- Enum.with_index(@cells) do %>
        <.cell
          content={cell}
          left={index == 0}
          right={index == Enum.count(@cells)-1}
          layout={Enum.at(@layout, index)}
          top={@top}
          bottom={@bottom}
        />
      <% end %>
    </div>
    """
  end

  defp cell_padding(%{top: true}), do: "pt-2"
  defp cell_padding(_), do: "p-0"

  attr(:content, :string, required: true)
  attr(:layout, :map, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)
  attr(:left, :boolean, default: false)
  attr(:right, :boolean, default: false)

  def cell(%{layout: layout, content: content} = assigns) do
    layout =
      if layout.type == :href and not valid_url?(content) do
        %{layout | type: :string}
      else
        layout
      end

    padding = cell_padding(assigns)
    assigns = assign(assigns, %{padding: padding, layout: layout})

    ~H"""
    <div class={@layout.width}>
      <div class="flex flex-col h-full">
        <%= if not @top do %>
          <div class="h-border bg-grey4 w-full" />
        <% end %>
        <div class="flex-grow">
          <div class="flex flex-row w-full h-full">
            <%= if not @left do %>
              <div class="w-border bg-grey4 h-full" />
            <% end %>
            <div class="flex-1 pl-4 pr-4 text-left">
              <div class={"flex flex-col justify-center h-full #{@layout.align} #{@padding}"}>
              <%= if @top do %>
                <Text.table_head><%= @content %></Text.table_head>
              <% else %>
                <Text.table_row>
                  <%= if @layout.type == :href do %>
                    <a class="underline text-primary" href={@content} target="_blank">Link</a>
                  <% else %>
                    <%= @content %>
                  <% end %>
                </Text.table_row>
              <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp valid_url?(string) do
    uri = URI.parse(string)
    uri.scheme != nil && uri.host =~ "."
  end
end
