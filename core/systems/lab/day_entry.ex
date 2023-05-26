defmodule Systems.Lab.DayEntry do
  use CoreWeb, :html

  import Frameworks.Pixel.Line

  attr(:entry, :map, required: true)

  def dynamic(%{entry: entry} = assigns) do
    assigns =
      assign(assigns, %{
        props: Map.delete(entry, :type),
        function:
          case entry do
            %{type: :time_slot} -> &time_slot_item/1
            %{type: :break} -> &break_item/1
          end
      })

    ~H"""
    <.function_component function={@function} props={@props} />
    """
  end

  def break_item(assigns) do
    ~H"""
    <div class="flex flex-row items-center h-6 w-full">
      <div class="h-1px w-full">
        <.line />
      </div>
    </div>
    """
  end

  attr(:enabled?, :boolean, default: true)
  attr(:bullet, :string, required: true)
  attr(:start_time, :integer, required: true)
  attr(:integer_of_seats, :integer, required: true)
  attr(:integer_of_reservations, :integer, required: true)
  attr(:target, :any)

  def time_slot_item(%{start_time: start_time} = assigns) do
    timestamp =
      if start_time >= 0 and start_time <= 2400 do
        hour = (start_time / 100) |> trunc()
        minute = "#{rem(start_time, 100)}" |> String.pad_leading(2, "0")
        "#{hour}:#{minute}"
      else
        "--:--"
      end

    assigns =
      assign(assigns, %{
        timestamp: timestamp
      })

    ~H"""
    <div class="flex flex-row items-center h-12 w-full">
      <div class="w-10">
        <.live_component
          module={Selector}
          id={@start_time}
          items={[%{id: :id, active: @enabled?}]}
          type={:checkbox}
          parent={@target}
        />
      </div>
      <div class="w-12">
        <Text.body_large color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= @bullet %>
        </Text.body_large>
      </div>
      <div class="w-16">
        <Text.body_medium color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= @timestamp %>
        </Text.body_medium>
      </div>
      <div class="flex-grow" />
      <div>
        <Text.body_medium>
          <%= if @enabled? do %>
            <span><%= dngettext("link-lab", "1 seat", "%{count} seats", @number_of_seats) %></span>
          <% else %>
            <span class="text-grey2"><%= dgettext("link-lab", "time.slot.item.available.label") %></span>
          <% end %>
        </Text.body_medium>
      </div>
      <div class="flex-grow" />
      <div class="w-32">
        <%= if @number_of_reservations > 0 do %>
          <Text.body_medium align="text-right" color="text-warning">
            <%= dngettext("link-lab", "1 reservation", "%{count} reservations", @number_of_reservations) %>
          </Text.body_medium>
        <% end %>
      </div>
    </div>
    """
  end
end
