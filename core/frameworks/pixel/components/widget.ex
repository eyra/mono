defmodule Frameworks.Pixel.Widget do
  use CoreWeb, :html

  import CoreWeb.UI.ProgressBar
  alias Frameworks.Pixel.Text

  attr(:integer, :integer, required: true)
  attr(:label, :string, required: true)
  attr(:color, :atom, default: :primary)
  attr(:target, :any, default: nil)
  attr(:target_direction, :atom, default: nil)

  def number(
        %{metric: metric, target: target, target_direction: target_direction, color: color} =
          assigns
      ) do
    number_color =
      case {metric, target, target_direction, color} do
        {metric, target, :up, _} when metric < target -> "text-warning"
        {metric, target, :up, _} when metric >= target -> "text-success"
        {metric, target, :down, _} when metric > target -> "text-delete"
        {metric, target, :down, _} when metric <= target -> "text-success"
        {_, _, _, :positive} -> "text-success"
        {_, _, _, :negative} -> "text-delete"
        {_, _, _, :warning} -> "text-warning"
        _ -> "text-primary"
      end

    assigns = assign(assigns, :number_color, number_color)

    ~H"""
    <div class="h-full">
      <div class="flex flex-col gap-2 rounded-lg shadow-2xl p-6 h-full">
        <div class={"font-title0 text-title0 #{@number_color}"}><%= @metric %></div>
        <Text.label><%= @label %></Text.label>
      </div>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:target_amount, :integer, required: true)
  attr(:done_amount, :integer, required: true)
  attr(:pending_amount, :integer, required: true)
  attr(:done_label, :string, required: true)
  attr(:pending_label, :string, required: true)
  attr(:target_label, :string, required: true)

  def progress(
        %{target_amount: target_amount, done_amount: done_amount, pending_amount: pending_amount} =
          assigns
      ) do
    left_over_amount = target_amount - (done_amount + pending_amount)
    size = max(target_amount, done_amount + pending_amount)

    assigns =
      assign(assigns, %{
        left_over_amount: left_over_amount,
        size: size
      })

    ~H"""
    <div class="rounded-lg shadow-2xl p-6 h-full">
      <Text.title5><%= @label %></Text.title5>
      <div class="mt-6" />
      <.progress_bar
        bg_color="bg-grey3"
        size={@size}
        bars={[
          %{color: :warning, size: @done_amount + @pending_amount},
          %{color: :success, size: @done_amount}
        ]}
      />

      <div class="flex flex-row flex-wrap items-center gap-y-4 gap-x-8 mt-6">
        <%= if @done_amount > 0 do %>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-success" />
            <Text.label><%= @done_amount %> <%= String.downcase(@done_label) %></Text.label>
          </div>
        <% end %>
        <%= if @pending_amount > 0 do %>
          <div class="flex flex-row items-center gap-3">
              <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-warning" />
              <Text.label><%= @pending_amount %> <%= String.downcase(@pending_label) %></Text.label>
            </div>
        <% end %>
        <%= if @left_over_amount > 0 do %>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-grey3" />
            <Text.label><%= @left_over_amount %> <%= String.downcase(@target_label) %></Text.label>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:scale, :integer, required: true)
  attr(:values, :list, required: true)

  def value_distribution(%{scale: scale, values: values} = assigns) do
    max = Statistics.max(values)
    count = Integer.floor_div(max, scale)

    value_count_list =
      Enum.to_list(0..count)
      |> Enum.map(fn index ->
        from = index * scale
        to = (index + 1) * scale
        Enum.count(values, &(&1 >= from and &1 < to))
      end)

    max_value_count = Statistics.max(value_count_list)

    bars =
      value_count_list
      |> Enum.with_index()
      |> Enum.map(fn {value_count, index} ->
        from = index * scale
        to = (index + 1) * scale

        range_label =
          if from == to - 1 do
            "#{from}"
          else
            "#{from} - #{to - 1}"
          end

        %{
          range_label: range_label,
          value_count: value_count,
          height: value_count / max_value_count
        }
      end)

    bar_width = "#{floor(100 / Enum.count(bars))}%"

    assigns =
      assign(assigns, %{
        bars: bars,
        bar_width: bar_width
      })

    ~H"""
    <div class="rounded-lg shadow-2xl p-6 h-full">
      <Text.title5><%= @label %></Text.title5>
      <div class="mt-4" />
      <div class="flex flex-col">
        <div class="flex flex-row gap-4">
          <%= for bar <- @bars do %>
            <div  style={"width: #{@bar_width}"}>
              <.value_distribution_bar {bar} />
            </div>
          <% end %>
        </div>
        <div class="flex flex-row mt-6 items-center">
          <div class="text-title7 font-title7 text-left text-grey1"><span class="text-primary">↑</span> Students</div>
          <div class="flex-grow" />
          <div class="text-title7 font-title7 text-right text-grey1">Credits <span class="text-primary">→</span></div>
        </div>
      </div>
    </div>
    """
  end

  @bar_height 200

  attr(:value_count, :integer, required: true)
  attr(:height, :integer, required: true)
  attr(:range_label, :string, required: true)

  def value_distribution_bar(
        %{value_count: value_count, height: height, range_label: range_label} = assigns
      ) do
    bar_height =
      if value_count == 0 do
        0
      else
        max(ceil(@bar_height * height), 4)
      end

    bar_top_height =
      if value_count == 0 do
        @bar_height - 2
      else
        @bar_height - height
      end

    assigns =
      assign(assigns, %{
        bar_height: bar_height,
        bar_top_height: bar_top_height,
        value_count: value_count,
        range_label: range_label
      })

    ~H"""
      <div class="flex flex-col items-center gap-2 w-full">
        <div class="flex flex-col items-center w-full">
          <div style={"height: #{@bar_top_height}px"} />
          <div class="pb-1 text-caption font-caption text-grey1"><%= @value_count %></div>
          <%= if @bar_height > 0 do %>
            <div
              style={"height: #{@bar_height}px"}
              class="flex-grow bg-primary w-full rounded-t-lg"
            />
          <% else %>
            <div class="bg-grey4 w-full h-2px" />
          <% end %>
        </div>
        <div class="text-caption font-caption text-grey2"><%= @range_label %></div>
      </div>
    """
  end
end
