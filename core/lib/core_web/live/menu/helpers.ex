defmodule CoreWeb.Menu.Helpers do
  use CoreWeb, :verified_routes

  alias CoreWeb.Menu.ItemsProvider

  alias Systems.{
    Support,
    NextAction
  }

  require CoreWeb.Gettext

  def home_item(menu_id, id, action, size) when is_atom(id) do
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

  def build_home(assigns, menu_id, id, config) do
    if Keyword.has_key?(config, menu_id) do
      action = action(assigns, id)
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

  def menu_item(assigns, menu_id, id, active_item, flags) when is_list(flags) do
    active? = id == active_item
    action = action(assigns, id)
    opts = opts(assigns, id, flags)

    menu_item(menu_id, id, active?, action, opts)
  end

  def build_item(assigns, menu_id, id, active_item, config) do
    flags = select_flags(menu_id, id, config)
    menu_item(assigns, menu_id, id, active_item, flags)
  end

  defp opts(assigns, id, flags) when is_list(flags) do
    user = Map.get(assigns, :current_user)

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

  def action(%{uri: uri} = assigns, :language) do
    parsed_uri = URI.parse(uri)

    redirect_url =
      case parsed_uri.query do
        nil -> parsed_uri.path
        query -> "#{parsed_uri.path}?#{query}"
      end

    action(assigns, :language, redirect_url)
  end

  def action(assigns, :language), do: action(assigns, :language, "\\")

  def action(_assigns, id) when is_atom(id), do: ItemsProvider.action(id)

  def action(_assigns, :language, redirect_url) when is_binary(redirect_url) do
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
      %{id: "en", name: CoreWeb.Gettext.gettext("English")},
      %{id: "nl", name: CoreWeb.Gettext.gettext("Dutch")}
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
