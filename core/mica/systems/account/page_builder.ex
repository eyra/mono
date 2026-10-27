defmodule Systems.Account.PageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Content.Adaptable

  def view_model(%Account.User{} = user, _assigns) do
    live_context = LiveContext.new(%{user_id: user.id})

    %{
      title: dgettext("eyra-account", "profile.title"),
      items: build_items(user, live_context),
      user: user,
      active_menu_item: :profile,
      layout: layout_for(user),
      menus_config: menus_config_for(user)
    }
  end

  defp layout_for(%Account.User{creator: true}), do: :workspace
  defp layout_for(%Account.User{}), do: :stripped

  defp menus_config_for(%Account.User{creator: true}) do
    {:workspace_menu_builder, [:mobile_menu, :mobile_navbar, :desktop_menu, :tablet_menu]}
  end

  # Participants share the bare auth/onboarding navbar — Account is a utility page.
  defp menus_config_for(%Account.User{}) do
    {:stripped_menu_builder, [:mobile_navbar, :desktop_navbar]}
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

  @doc "Keys of all account tabs in display order, before visibility filtering."
  def tab_keys, do: Enum.map(Core.SaaS.account_tabs(), & &1.key())

  def tab_keys(user) do
    visible_tabs(user)
    |> Enum.map(& &1.key())
  end

  defp visible_tabs(user) do
    Core.SaaS.account_tabs()
    |> Enum.filter(& &1.visible?(user))
  end
end
