defmodule CoreWeb.Menu.ItemsProvider do
  @callback values() :: map()

  defp menu_items, do: Application.fetch_env!(:core, :menu_items)

  def items(), do: menu_items().values()
  def item(item_id), do: items()[item_id]

  def info(item_id) do
    case CoreWeb.Menu.ItemsProvider.item(item_id) do
      nil -> exit("Menu item :#{item_id} not found in configuration")
      item -> item
    end
  end

  def action(item_id) do
    case CoreWeb.Menu.ItemsProvider.item(item_id) do
      nil -> exit("Menu item :#{item_id} not found in configuration")
      %{action: action} -> action
      _ -> exit("Menu item #{item_id} has no configuration for action")
    end
  end

  def icon(item_id), do: item_id

  def title(item_id) do
    case CoreWeb.Menu.ItemsProvider.item(item_id) do
      nil -> exit("Menu item :#{item_id} not found in configuration")
      %{title: title} -> title
      _ -> exit("Menu item #{item_id} has no configuration for title")
    end
  end

  def counter(_item_id, _user_state), do: nil
end
