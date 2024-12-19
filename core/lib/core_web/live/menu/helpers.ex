defmodule CoreWeb.Menu.Helpers do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.Menu.ItemsProvider

  alias Systems.{
    Support,
    NextAction
  }

  def build_home(menu_id, id, config, uri) do
    if Keyword.has_key?(config, menu_id) do
      action = action(id, uri)
      flags = select_flags(menu_id, id, config)

      size =
        if Enum.member?(flags, :wide) do
          :wide
        else
          :narrow
        end

      home_item(menu_id, id, action, size)
    else
      nil
    end
  end

  defp home_item(menu_id, id, action, size) when is_atom(id) do
    face = %{
      type: :menu_home,
      icon: id,
      size: size
    }

    %{
      id: id,
      menu_id: menu_id,
      action: action,
      face: face
    }
  end

  def menu_item(menu_id, id, active?, action, %{} = opts) when is_atom(id) do
    face = %{
      type: :menu_item,
      active?: active?,
      icon: Map.get(opts, :icon),
      title: Map.get(opts, :title),
      counter: Map.get(opts, :counter)
    }

    %{
      id: id,
      menu_id: menu_id,
      action: action,
      face: face
    }
  end

  def menu_item(menu_id, id, active_item, flags, user, uri) when is_list(flags) do
    active? = id == active_item
    action = action(id, uri)
    opts = opts(id, flags, user)

    menu_item(menu_id, id, active?, action, opts)
  end

  def build_item(menu_id, id, active_item, config, user, uri) do
    flags = select_flags(menu_id, id, config)
    menu_item(menu_id, id, active_item, flags, user, uri)
  end

  defp opts(id, flags, user) when is_list(flags) do
    icon =
      if Enum.member?(flags, :icon) do
        icon(id)
      else
        nil
      end

    title =
      if Enum.member?(flags, :title) do
        title(id)
      else
        nil
      end

    counter =
      if Enum.member?(flags, :counter) do
        counter(id, user)
      else
        nil
      end

    %{
      icon: icon,
      title: title,
      counter: counter
    }
  end

  def action(:language, nil), do: action(:language, nil, "\\")

  def action(:language, uri) do
    parsed_uri = URI.parse(uri)

    redirect_url =
      case parsed_uri.query do
        nil -> parsed_uri.path
        query -> "#{parsed_uri.path}?#{query}"
      end

    action(:language, uri, redirect_url)
  end

  def action(id, _uri) when is_atom(id), do: ItemsProvider.action(id)

  def action(:language, _uri, redirect_url) when is_binary(redirect_url) do
    [locale] = supported_languages()

    %{
      type: :http_get,
      to: ~p"/switch-language/#{locale.id}?redir=#{redirect_url}"
    }
  end

  def icon(:language) do
    [locale] = supported_languages()
    locale.id
  end

  def icon(id) when is_atom(id), do: id

  def title(:language) do
    [locale] = supported_languages()
    locale.name
  end

  def title(id) when is_atom(id), do: ItemsProvider.title(id)

  def counter(:todo, user), do: NextAction.Public.count_next_actions(user)
  def counter(:support, _), do: Support.Public.count_open_tickets()
  def counter(id, user) when is_atom(id), do: ItemsProvider.counter(id, user)

  def supported_languages do
    current_locale = Gettext.get_locale(CoreWeb.Gettext)

    [
      %{id: "en", name: gettext("English")}
    ]
    |> Enum.reject(fn %{id: locale} -> current_locale == locale end)
  end

  def select_items(menu_id, config) do
    case Kernel.get_in(config, [menu_id]) do
      nil ->
        case Kernel.get_in(config, [:default]) do
          nil -> config
          items -> items
        end

      items ->
        items
    end
  end

  def select_flags(menu_id, id, config) do
    case Kernel.get_in(config, [menu_id, id]) do
      nil ->
        case Kernel.get_in(config, [menu_id, :default]) do
          nil -> Keyword.get(config, menu_id, [])
          flags -> flags
        end

      flags ->
        flags
    end
  end

  def append(list, extra, cond \\ true) do
    if cond, do: list ++ [extra], else: list
  end
end
