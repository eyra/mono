defmodule Systems.Support.TicketPageBuilder do
  import CoreWeb.Gettext
  alias Systems.Support

  def view_model(ticket, _assigns) do
    %{
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      timestamp: get_timestamp(ticket),
      member: to_member(ticket),
      tag: Support.TicketModel.tag(ticket),
      button: create_button(ticket),
      active_menu_item: :support
    }
  end

  defp create_button(%{completed_at: completed_at}) when is_nil(completed_at) do
    %{
      action: %{type: :send, event: "close_ticket"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-admin", "close.ticket.button"),
        text_color: "text-delete"
      }
    }
  end

  defp create_button(_) do
    %{
      action: %{type: :send, event: "reopen_ticket"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-admin", "reopen.ticket.button"),
        text_color: "text-primary"
      }
    }
  end

  defp get_timestamp(%{updated_at: updated_at}) do
    updated_at
    |> CoreWeb.UI.Timestamp.apply_timezone()
    |> CoreWeb.UI.Timestamp.humanize()
  end

  defp to_member(%{
         id: id,
         title: title,
         user: %{
           email: email,
           researcher: researcher,
           student: student,
           coordinator: coordinator,
           profile: %{
             fullname: fullname,
             photo_url: photo_url
           },
           features: %{
             gender: gender
           }
         }
       }) do
    role =
      cond do
        coordinator -> dgettext("eyra-admin", "role.coordinator")
        researcher -> dgettext("eyra-admin", "role.researcher")
        student -> dgettext("eyra-admin", "role.student")
        true -> nil
      end

    action = %{type: :http_get, to: "mailto:#{email}?subject=Re: [##{id}] #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: gender,
      button_large: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-ui", "mailto.button"),
          bg_color: "bg-tertiary",
          text_color: "text-grey1"
        }
      },
      button_small: %{
        action: action,
        face: %{type: :icon, icon: :contact_tertiary}
      }
    }
  end
end
