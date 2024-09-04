defmodule CoreWeb.Menus do
  def build_menus({menu_builder, menus, active_menu_item}, user, uri),
    do: build_menus(menu_builder, menus, active_menu_item, user, uri)

  def build_menus(menu_builder, menus, active_menu_item, user, uri) do
    Enum.reduce(menus, %{}, fn menu_item, acc ->
      Map.put(acc, menu_item, build_menu(menu_builder, menu_item, active_menu_item, user, uri))
    end)
  end

  defp build_menu(menu_builder, menu_item, active_menu_item, user, uri) do
    menu_builder_module(menu_builder).build_menu(menu_item, active_menu_item, user, uri)
  end

  def menu_builder_module(menu_builder) do
    Application.fetch_env!(:core, menu_builder)
  end
end
