defmodule Systems.Account.UserProfilePageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Content.Adaptable

  @tabs [
    Systems.Account.ProfileTab,
    Systems.Account.PayoutsTab,
    Systems.Account.FeaturesTab
  ]

  def view_model(%Account.User{} = user, _assigns) do
    live_context = LiveContext.new(%{user_id: user.id})

    %{
      title: dgettext("eyra-account", "profile.title"),
      items: build_items(user, live_context),
      signout_button: build_signout_button(),
      user: user,
      active_menu_item: :profile
    }
  end

  defp build_signout_button do
    %{
      action: %{type: :http_delete, to: ~p"/user/session"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-ui", "menu.item.signout"),
        border_color: "border-delete",
        text_color: "text-delete"
      }
    }
  end

  def build_items(user, live_context) do
    visible_tabs(user)
    |> Enum.map(&tab_to_item(&1.build(user, live_context)))
  end

  defp tab_to_item(%{id: id, title: title} = tab) do
    Adaptable.Item.new(id, :profile, title,
      element: Map.get(tab, :element),
      child: Map.get(tab, :child)
    )
  end

  def tab_keys(user) do
    visible_tabs(user)
    |> Enum.map(& &1.key())
  end

  defp visible_tabs(user) do
    @tabs
    |> Enum.filter(& &1.visible?(user))
  end
end
