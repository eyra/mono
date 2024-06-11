defmodule Systems.Pool.ResearcherItemBuilder do
  import CoreWeb.Gettext

  alias Systems.Account.User

  def view_model(
        %{
          email: email,
          profile: %{
            fullname: fullname,
            photo_url: photo_url
          }
        } = user,
        %{
          title: title
        }
      ) do
    role = dgettext("eyra-admin", "role.creator")
    action = %{type: :http_get, to: "mailto:#{email}?subject=Re: #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: User.get_gender(user),
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
        face: %{type: :icon, icon: :contact, color: :tertiary}
      }
    }
  end
end
