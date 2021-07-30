defmodule CoreWeb.Menu.ItemsProvider do
  @type item() :: map()
  @callback values() :: list(item)

  import CoreWeb.Gettext

  defp menu_items, do: Application.fetch_env!(:core, :menu_items)

  def items(), do: menu_items().values()
  def item(item_id), do: items()[item_id]

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote do
        for {item_id, %{domain: domain}} <- CoreWeb.Menu.ItemsProvider.items() do
          quote do
            dgettext(unquote(domain), unquote("menu.item.#{item_id}"))
          end
        end
      end

      def info(item_id) do
        case CoreWeb.Menu.ItemsProvider.item(item_id) do
          nil -> exit("Menu item :#{item_id} not found in configuration")
          item -> item
        end
      end

      def title(item_id) do
        case CoreWeb.Menu.ItemsProvider.item(item_id) do
          nil ->
            exit("Menu item :#{item_id} not found in configuration")

          %{domain: domain} ->
            Gettext.dgettext(CoreWeb.Gettext, domain, "menu.item.#{item_id}")

          _ ->
            exit("Menu item #{item_id} has no configuration for domain")
        end
      end
    end
  end
end
