defmodule Systems.Benchmark.LeaderboardView do
  use CoreWeb, :html

  attr(:categories, :list, required: true)

  def leaderboard(assigns) do
    ~H"""
    <div class="flex flex-col gap-12">
      <%= for category <- @categories do %>
        <.category name={category.name} scores={category.scores} />
      <% end %>
    </div>
    """
  end

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

  def category(%{name: name, scores: scores} = assigns) do
    title = String.capitalize(String.replace(name, "_", " "))

    items =
      scores
      |> Enum.map(&to_item/1)
      |> Enum.sort_by(& &1.updated_at, {:asc, NaiveDateTime})
      |> Enum.sort_by(& &1.score, :desc)

    assigns = assign(assigns, %{title: title, items: items})

    ~H"""
    <div>
      <Text.title4><%= @title %></Text.title4>
      <.spacing value="XS" />
      <div class="overflow-hidden border-2 border-grey4 rounded-lg">
        <div class="w-full border-spacing-0">
          <div class="h-12">
            <.row top={true} cells={["Position", "Team", "Method", "Github", "Score"]}/>
          </div>
          <%= for {item, index} <- Enum.with_index(@items) do %>
            <.row
              bottom={index == Enum.count(@items)-1}
              cells={[index+1, item.name, item.description, item.link, item.score]}
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:cells, :list, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)

  def row(assigns) do
    ~H"""
    <div class="h-12 flex flex-row ">
      <%= for {cell, index} <- Enum.with_index(@cells) do %>
        <.cell
          content={cell}
          index={index}
          left={index == 0}
          right={index == Enum.count(@cells)-1}
          top={@top}
          bottom={@bottom}
        />
      <% end %>
    </div>
    """
  end

  defp cell_width(0), do: "w-24"
  defp cell_width(3), do: "w-24"
  defp cell_width(4), do: "w-24"
  defp cell_width(_), do: "flex-1"

  defp cell_padding(%{top: true}), do: "pt-2"
  defp cell_padding(_), do: "p-0"

  defp text_align(4), do: "text-right"
  defp text_align(_), do: "text-left"

  attr(:content, :string, required: true)
  attr(:index, :string, required: true)
  attr(:top, :boolean, default: false)
  attr(:bottom, :boolean, default: false)
  attr(:left, :boolean, default: false)
  attr(:right, :boolean, default: false)

  def cell(%{index: index} = assigns) do
    padding = cell_padding(assigns)
    width = cell_width(index)
    align = text_align(index)

    assigns = assign(assigns, %{padding: padding, width: width, align: align})

    ~H"""
    <div class={"#{@width}"}>
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
              <div class={"flex flex-col justify-center h-full #{@align} #{@padding}"}>
              <%= if @top do %>
                <Text.table_head><%= @content %></Text.table_head>
              <% else %>
                <Text.table_row>
                  <%= if @index == 3 do %>
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
