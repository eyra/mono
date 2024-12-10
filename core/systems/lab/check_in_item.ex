defmodule Systems.Lab.CheckInItem do
  use CoreWeb, :html

  use Gettext, backend: CoreWeb.Gettext
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Lab
  }

  defp title(%{email: nil, subject: subject}), do: "Subject #{subject}"
  defp title(%{email: email}), do: email

  defp message(%{status: :reservation_available, time_slot: time_slot}),
    do: time_slot_message(time_slot)

  defp message(%{status: :reservation_not_found}),
    do: "❔ " <> dgettext("link-lab", "search.subject.noreservation")

  defp message(%{status: :reservation_cancelled}),
    do: "❌ " <> dgettext("link-lab", "search.subject.cancelled")

  defp message(%{status: :reservation_expired}),
    do: "❔ " <> dgettext("link-lab", "search.subject.expired")

  defp message(%{
         status: :signed_up_already,
         email: email,
         subject: subject,
         check_in_date: check_in_date
       })
       when email != nil,
       do:
         "✅ " <>
           dgettext("link-lab", "search.subject.checkedin.full",
             date: date_string(check_in_date),
             subject: subject
           )

  defp message(%{status: :signed_up_already, check_in_date: check_in_date}),
    do:
      "✅ " <>
        dgettext("link-lab", "search.subject.checkedin.short", date: date_string(check_in_date))

  defp date_string(nil), do: ""

  defp date_string(date) do
    date_string =
      date
      |> Timestamp.apply_timezone()
      |> Timestamp.humanize()

    " #{date_string}"
  end

  defp time_slot_message(nil), do: "🗓 " <> dgettext("link-lab", "search.subject.reservation")
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

  attr(:id, :string, required: true)
  attr(:status, :atom, required: true)
  attr(:email, :string)
  attr(:subject, :integer)
  attr(:time_slot, :any)
  attr(:check_in_date, :any)
  attr(:target, :any)

  def check_in_item(assigns) do
    ~H"""
    <tr class="h-12">
      <td class="pr-8 font-body text-bodymedium sm:text-bodylarge flex-wrap text-white">
        <%= title(assigns) %>
      </td>
      <td class="pr-8 font-body text-bodysmall sm:text-bodymedium text-white">
        <span class="whitespace-pre-wrap"><%= message(assigns) %></span>
      </td>
      <td>
        <div class="flex flex-row gap-4">
          <%= for button <- buttons(assigns) do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </td>
    </tr>
    """
  end
end
