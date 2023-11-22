defmodule CoreWeb.Menu.Builder do
  @type type :: atom()
  @type socket :: map()
  @type active_item :: atom()
  @type menu :: map()
  @type user :: map() | nil
  @type item :: atom()

  @callback build_menu(socket, type, active_item) :: menu
  @callback include_map(user) :: map()

  alias Systems.Admin

  def include_map(user) do
    %{
      admin: Admin.Public.admin?(user),
      support: Admin.Public.admin?(user),
      debug: Admin.Public.admin?(user),
      profile: Core.Accounts.internal?(user),
      signout: not is_nil(user),
      signin: is_nil(user)
    }
  end

  defmacro __using__(home: home) do
    quote do
      @behaviour unquote(__MODULE__)
      import CoreWeb.Menu.Helpers

      @impl true
      def build_menu(assigns, menu_id, active_item) do
        builder = &build_item(assigns, menu_id, &1, active_item, @item_flags)

        primary = select_items(menu_id, @primary)
        secondary = select_items(menu_id, @secondary)

        %{
          home: build_home(assigns, menu_id, unquote(home), @home_flags),
          primary: build(assigns, primary, builder),
          secondary: build(assigns, secondary, builder)
        }
      end

      defp build(assigns, items, builder) do
        user = Map.get(assigns, :current_user)

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
