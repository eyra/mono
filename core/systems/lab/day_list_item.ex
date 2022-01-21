defmodule Systems.Lab.DayListItem do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text.BodyMedium

  prop(id, :any, required: true)
  prop(target, :any)

  prop(enabled?, :boolean, default: true)
  prop(date, :date, required: true)
  prop(location, :string, required: true)
  prop(number_of_timeslots, :number, required: true)
  prop(number_of_seats, :number, required: true)

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

  def render(assigns) do
    ~F"""
      <tr>
        <td>
          <BodyMedium color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {datestamp(@date)}
          </BodyMedium>
        </td>
        <td class="p-4"></td>
        <td>
          <BodyMedium color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {dngettext("link-lab", "1 timeslot", "%{count} time slots", @number_of_timeslots)}
          </BodyMedium>
        </td>
        <td class="p-4"></td>
        <td>
          <BodyMedium color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {dngettext("link-lab", "1 seat", "%{count} seats", @number_of_seats)}
          </BodyMedium>
        </td>
        <td class="p-4"></td>
        <td>
          <BodyMedium color={if @enabled? do "text-grey1" else "text-grey2" end}>
            {@location}
          </BodyMedium>
        </td>
        <td class="p-4"></td>
        <td>
          <DynamicButton vm={edit_button(assigns)} />
        </td>
        <td class="p-4"></td>
        <td>
          <div class="flex flex-row gap-4 items-center">
            <DynamicButton :for={button <- right_buttons(assigns)} vm={button} />
          </div>
        </td>
      </tr>
    """
  end
end

defmodule Systems.Lab.DayListItem.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.DayListItem,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Day list item",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
    <div class="w-full">
      <DayListItem id={"1"} target={@myself} enabled?={true} date={~D[2022-01-14]} location={"SBE lab (HG 04.48)"} number_of_timeslots={1} number_of_seats={1} />
    </div>
    """
  end
end
