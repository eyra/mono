defmodule Systems.Graphite.LeaderboardCategoryView do
  use CoreWeb, :html

  defp to_item(%{
         score: score,
         submission: %{
           updated_at: updated_at,
           github_commit_url: github_commit_url,
           description: description,
           spot: %{name: name}
         }
       }) do
    # max 6 decimal precision
    score = trunc(score * 1_000_000) / 1_000_000

    %{
      name: name,
      description: description,
      score: score,
      link: github_commit_url,
      updated_at: updated_at
    }
  end

  attr(:name, :string, required: true)
  attr(:scores, :list, required: true)

  def category(%{scores: scores} = assigns) do
    items =
      scores
      |> Enum.map(&to_item/1)
      |> Enum.sort_by(& &1.updated_at, {:asc, NaiveDateTime})
      |> Enum.sort_by(& &1.score, :desc)

    head_cells = [
      dgettext("eyra-benchmark", "leaderboard.position.label"),
      dgettext("eyra-benchmark", "leaderboard.team.label"),
      dgettext("eyra-benchmark", "leaderboard.method.label"),
      dgettext("eyra-benchmark", "leaderboard.github.label"),
      dgettext("eyra-benchmark", "leaderboard.score.label")
    ]

    layout = [
      %{type: :text, width: "w-24", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :text, width: "flex-1", align: "text-left"},
      %{type: :href, width: "w-24", align: "text-center"},
      %{type: :text, width: "w-24", align: "text-right"}
    ]

    assigns = assign(assigns, %{items: items, head_cells: head_cells, layout: layout})

    ~H"""
    <div class="overflow-hidden border-2 border-grey4 rounded-lg">
      <div class="w-full border-spacing-0">
        <div class="h-12">
          <.row top={true} cells={@head_cells} layout={@layout}/>
        </div>
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <.row
            bottom={index == Enum.count(@items)-1}
            cells={["#{index+1}.", item.name, item.description, item.link, item.score]}
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

  def cell(assigns) do
    padding = cell_padding(assigns)
    assigns = assign(assigns, %{padding: padding})

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
end
