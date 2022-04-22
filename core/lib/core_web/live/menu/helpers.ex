defmodule CoreWeb.Menu.Helpers do
  use CoreWeb.Menu.ItemsProvider

  require CoreWeb.Gettext
  alias CoreWeb.Router.Helpers, as: Routes
  defp size(%{size: size}), do: size
  defp size(_), do: :small

  def live_item(socket, menu_id, id, user, active_item, use_icon \\ true, counter \\ nil)
      when is_atom(id) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{
          name: id,
          size: size
        }
      else
        nil
      end

    path = path(socket, info.target)
    action = %{target: path, dead?: user == nil}

    %{
      menu_id: menu_id,
      id: id,
      title: title,
      icon: icon,
      action: action,
      active?: active_item === id,
      counter: counter
    }
  end

  defp path(socket, Systems.Home.LandingPage) do
    Routes.landing_page_path(socket, :show)
  end

  defp path(socket, target) do
    Routes.live_path(socket, target)
  end

  def account_item(socket, menu_id, user, active_item, use_icon \\ true) do
    if user != nil do
      live_item(socket, menu_id, :profile, user, active_item, use_icon)
    else
      user_session_item(socket, menu_id, :signin, use_icon)
    end
  end

  def alpine_item(menu_id, id, active_item, use_icon, overlay?) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{
          name: id,
          size: size
        }
      else
        nil
      end

    method = :alpine
    action = %{target: info.target, method: method, overlay?: overlay?}

    %{
      menu_id: menu_id,
      id: id,
      title: title,
      icon: icon,
      action: action,
      active?: active_item === id
    }
  end

  def user_session_item(socket, menu_id, id, use_icon) do
    info = info(id)
    size = size(info)

    title =
      if size == :large do
        nil
      else
        title(id)
      end

    icon =
      if use_icon do
        %{name: id, size: size}
      else
        nil
      end

    method =
      if info.target === :delete do
        :delete
      else
        :get
      end

    action = %{target: Routes.user_session_path(socket, info.target), method: method, dead?: true}
    %{menu_id: menu_id, id: id, title: title, icon: icon, action: action}
  end

  def language_switch_item(socket, menu_id, icon_only? \\ false)

  def language_switch_item(%{assigns: %{uri: uri}} = socket, menu_id, icon_only?) do
    parsed_uri = URI.parse(uri)

    redir =
      case parsed_uri.query do
        nil -> parsed_uri.path
        query -> "#{parsed_uri.path}?#{query}"
      end

    language_switch_item(socket, menu_id, redir, icon_only?)
  end

  def language_switch_item(socket, menu_id, icon_only?) do
    language_switch_item(socket, menu_id, "\\", icon_only?)
  end

  defp language_switch_item(socket, menu_id, redir, icon_only?) do
    [locale | _] = supported_languages()

    title =
      if icon_only? do
        nil
      else
        locale.name
      end

    icon = %{name: locale.id, size: :small}

    path = Routes.language_switch_path(socket, :index, locale.id, redir: redir)
    action = %{target: path, dead?: true}
    %{menu_id: menu_id, id: locale.id, title: title, icon: icon, action: action}
  end

  def supported_languages do
    current_locale = Gettext.get_locale(CoreWeb.Gettext)

    [
      %{id: "en", name: CoreWeb.Gettext.gettext("English")},
      %{id: "nl", name: CoreWeb.Gettext.gettext("Dutch")}
    ]
    |> Enum.reject(fn %{id: locale} -> current_locale == locale end)
  end
end
