defmodule Systems.Lab.DayList do
  use CoreWeb, :html

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text

  defp datestamp(%Date{} = date) do
    Timestamp.humanize_date(date)
    |> Macro.camelize()
  end

  defp edit_button(%{id: id, target: target}) do
    %{
      action: %{type: :send, event: "edit_day", item: id, target: target},
      face: %{
        type: :label,
        label: dgettext("link-lab", "edit.day.button"),
        font: "text-bodymedium font-body underline"
      }
    }
  end

  defp right_buttons(%{id: id, target: target}) do
    [
      %{
        action: %{type: :send, event: "duplicate_day", item: id, target: target},
        face: %{type: :icon, icon: :duplicate, alt: dgettext("link-lab", "duplicate.day.button")}
      },
      %{
        action: %{type: :send, event: "remove_day", item: id, target: target},
        face: %{type: :icon, icon: :remove, alt: dgettext("link-ui", "delete.button")}
      }
    ]
  end

  attr(:id, :any, required: true)
  attr(:target, :any)

  attr(:enabled?, :boolean, default: true)
  attr(:date, :map, required: true)
  attr(:location, :string, required: true)
  attr(:number_of_timeslots, :integer, required: true)
  attr(:number_of_seats, :integer, required: true)

  def item(assigns) do
    ~H"""
    <tr>
      <td>
        <Text.body_medium color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= datestamp(@date) %>
        </Text.body_medium>
      </td>
      <td class="p-4" />
      <td>
        <Text.body_medium color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= dngettext("link-lab", "1 time slot", "%{count} time slots", @number_of_timeslots) %>
        </Text.body_medium>
      </td>
      <td class="p-4" />
      <td>
        <Text.body_medium color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= dngettext("link-lab", "1 seat", "%{count} seats", @number_of_seats) %>
        </Text.body_medium>
      </td>
      <td class="p-4" />
      <td>
        <Text.body_medium color={if @enabled? do
          "text-grey1"
        else
          "text-grey2"
        end}>
          <%= @location %>
        </Text.body_medium>
      </td>
      <td class="p-4" />
      <td>
        <Button.dynamic {edit_button(assigns)} />
      </td>
      <td class="p-4" />
      <td>
        <div class="flex flex-row gap-4 items-center">
          <%= for button <- right_buttons(assigns) do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </td>
    </tr>
    """
  end
end
