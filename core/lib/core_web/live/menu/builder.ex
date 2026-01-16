defmodule CoreWeb.Menu.Builder do
  @type type :: atom()
  @type socket :: map()
  @type active_item :: atom()
  @type menu :: map()
  @type user :: map() | nil
  @type uri :: binary() | nil
  @type item :: atom()

  @callback build_menu(type, active_item, user, uri) :: menu
  @callback include_map(user) :: map()

  alias Systems.Admin
  alias Systems.Account

  def include_map(user) do
    %{
      admin: Admin.Public.admin_access?(user),
      support: Admin.Public.admin?(user),
      debug: Admin.Public.admin?(user),
      profile: Account.Public.internal?(user),
      signout: not is_nil(user),
      signin: is_nil(user)
    }
  end

  defmacro __using__(home: home) do
    quote do
      @behaviour unquote(__MODULE__)
      import CoreWeb.Menu.Helpers

      @impl true
      def build_menu(menu_id, active_item, user, uri) do
        builder = &build_item(menu_id, &1, active_item, @item_flags, user, uri)

        primary = select_items(menu_id, @primary)
        secondary = select_items(menu_id, @secondary)

        %{
          home: build_home(menu_id, unquote(home), @home_flags, uri),
          primary: build(primary, builder, user),
          secondary: build(secondary, builder, user)
        }
      end

      defp build(items, builder, user) do
        include_map =
          Map.merge(
            unquote(__MODULE__).include_map(user),
            include_map(user)
          )

        items
        |> Enum.filter(&Map.get(include_map, &1, true))
        |> Enum.map(&builder.(&1))
      end
    end
  end
end
