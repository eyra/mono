defmodule Systems.Lab.CheckInItem do
  use CoreWeb.UI.Component

  import CoreWeb.Gettext

  alias Systems.{
    Lab
  }

  prop(id, :string, required: true)
  prop(status, :atom, required: true)
  prop(email, :string)
  prop(subject, :integer)
  prop(time_slot, :any)
  prop(target, :any)

  defp title(%{email: nil, subject: subject}), do: "Subject #{subject}"
  defp title(%{email: email}), do: email

  defp message(%{status: :reservation_available, time_slot: time_slot}),
    do: time_slot_message(time_slot)

  defp message(%{status: :reservation_not_found}), do: "❔ No reservation available"
  defp message(%{status: :reservation_canceled}), do: "❌ Reservation canceled"

  defp message(%{status: :reservation_expired}),
    do: "❔ " <> dgettext("link-lab", "search.subject.expired")

  defp message(%{status: :signed_up_already, subject: %{public_id: public_id}}),
    do: "✅ Subject #{public_id}"

  defp message(%{status: :signed_up_already}), do: "✅ Signed up"

  defp time_slot_message(nil), do: "🗓 Reservation found"
  defp time_slot_message(time_slot), do: "🗓  " <> Lab.TimeSlotModel.message(time_slot)

  defp buttons(%{status: :signed_up_already}), do: []

  defp buttons(%{id: id, target: target}),
    do: [
      %{
        action: %{type: :send, item: id, target: target, event: "accept"},
        face: %{
          type: :icon,
          icon: :add,
          color: :tertiary,
          label: "Sign up"
        }
      }
    ]

  @impl true
  def render(assigns) do
    ~F"""
      <tr class="h-12">
        <td class="pr-8 font-body text-bodymedium sm:text-bodylarge flex-wrap text-white">
          {title(assigns)}
        </td>
        <td class="pr-8 font-body text-bodysmall sm:text-bodymedium text-white" >
          <span class="whitespace-pre-wrap">{message(assigns)}</span>
        </td>
        <td>
          <div class="flex flex-row gap-4">
            <DynamicButton :for={button <- buttons(assigns)} vm={button} />
          </div>
        </td>
      </tr>
    """
  end
end

defmodule Systems.Lab.CheckInItem.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.CheckInItem,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Check in list item",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  data(item1, :map,
    default: %{
      id: 1,
      subject: 1,
      status: :reservation_available,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  data(item2, :map,
    default: %{
      id: 2,
      subject: 12,
      status: :reservation_expired,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  data(item3, :map,
    default: %{
      id: 3,
      subject: 123,
      status: :reservation_canceled,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  data(item4, :map,
    default: %{
      id: 4,
      subject: 1234,
      status: :signed_up_already,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  data(item5, :map,
    default: %{
      id: 5,
      email: "e.vanderveen@eyra.co",
      status: :reservation_available,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  data(item6, :map,
    default: %{
      id: 6,
      email: "e.vanderveen@eyra.co",
      status: :signed_up_already,
      subject: 6
    }
  )

  data(item7, :map,
    default: %{
      id: 7,
      email: "e.vanderveen@eyra.co",
      status: :reservation_not_found
    }
  )

  data(item8, :map,
    default: %{
      id: 8,
      email: "e.vanderveen@eyra.co",
      status: :reservation_canceled,
      time_slot: %{location: "SBE lab", start_time: CoreWeb.UI.Timestamp.now()}
    }
  )

  @impl true
  def handle_event(event, %{"item" => item}, socket) do
    IO.puts("#{event}: #{item}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div class="p-8 rounded-lg bg-grey1 ">
      <table>
        <CheckInItem {...@item1} />
        <CheckInItem {...@item2} />
        <CheckInItem {...@item3} />
        <CheckInItem {...@item4} />
        <CheckInItem {...@item5} />
        <CheckInItem {...@item7} />
        <CheckInItem {...@item8} />
        <CheckInItem {...@item6} />
      </table>
    </div>
    """
  end
end
