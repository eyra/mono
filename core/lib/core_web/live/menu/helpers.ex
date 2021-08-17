defmodule CoreWeb.Menu.Helpers do
  use CoreWeb.Menu.ItemsProvider

  require CoreWeb.Gettext

  alias CoreWeb.Router.Helpers, as: Routes

  defp size(%{size: size}), do: size
  defp size(_), do: :small

  def live_item(socket, id, active_item, use_icon \\ true, counter \\ nil) when is_atom(id) do
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

    path = Routes.live_path(socket, info.target)
    action = %{target: path}

    %{
      id: id,
      title: title,
      icon: icon,
      action: action,
      active?: active_item === id,
      counter: counter
    }
  end

  def account_item(socket, is_logged_in, active_item, use_icon \\ true) do
    if is_logged_in do
      live_item(socket, :profile, active_item, use_icon)
    else
      user_session_item(socket, :signin, use_icon)
    end
  end

  def alpine_item(id, active_item, use_icon, overlay?) do
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
      id: id,
      title: title,
      icon: icon,
      action: action,
      active?: active_item === id
    }
  end

  def user_session_item(socket, id, use_icon) do
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
    %{id: id, title: title, icon: icon, action: action}
  end

  def language_switch_item(socket, page_id) do
    [locale | _] = supported_languages()

    title = locale.name
    icon = %{name: locale.id, size: :small}

    redir =
      if page_id do
        Routes.live_path(socket, socket.view, page_id)
      else
        Routes.live_path(socket, socket.view)
      end

    path = Routes.language_switch_path(socket, :index, locale.id, redir: redir)
    action = %{target: path, dead?: true}
    %{id: locale.id, title: title, icon: icon, action: action}
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
