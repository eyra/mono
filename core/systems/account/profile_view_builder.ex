defmodule Systems.Account.ProfileViewBuilder do
  @moduledoc """
  Builder for ProfileView that constructs the view model for user profile editing.
  """
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  def view_model(%Account.UserProfileEditModel{user_id: user_id} = entity, assigns) do
    user = Map.get(assigns, :user) || Account.Public.get_user!(user_id)
    changeset = Account.UserProfileEditModel.changeset(entity, :mount, %{})
    show_signout_button = Map.get(assigns, :show_signout_button, true)
    show_email = Map.get(assigns, :show_email, true)
    show_top_margin = Map.get(assigns, :show_top_margin, false)

    signout_button =
      if show_signout_button do
        %{
          action: %{type: :http_delete, to: ~p"/user/session"},
          face: %{
            type: :secondary,
            label: dgettext("eyra-ui", "menu.item.signout"),
            border_color: "border-delete",
            text_color: "text-delete"
          }
        }
      else
        nil
      end

    %{
      title: dgettext("eyra-account", "profile.tab.profile.title"),
      changeset: changeset,
      entity: entity,
      user: user,
      signout_button: signout_button,
      show_email: show_email,
      show_top_margin: show_top_margin,
      photo_url: entity.photo_url,
      fullname_label: dgettext("eyra-account", "fullname.label"),
      displayname_label: dgettext("eyra-account", "displayname.label"),
      title_label: dgettext("eyra-account", "professionaltitle.label"),
      email_label: dgettext("eyra-account", "email.label"),
      choose_photo_text: dgettext("eyra-account", "choose.profile.photo.file"),
      choose_other_photo_text: dgettext("eyra-account", "choose.other.profile.photo.file")
    }
  end
end
