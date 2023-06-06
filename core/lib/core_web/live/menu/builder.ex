defmodule CoreWeb.Menu.Builder do
  @type type :: atom()
  @type socket :: map()
  @type active_item :: atom()
  @type menu :: map()
  @type user :: map() | nil
  @type item :: atom()

  @callback build_menu(socket, type, active_item) :: menu
  @callback can_access?(user, item) :: boolean()

  alias Systems.Admin

  def can_access?(user, :admin), do: Admin.Public.admin?(user)
  def can_access?(user, :support), do: Admin.Public.admin?(user)
  def can_access?(user, :debug), do: Admin.Public.admin?(user)
  def can_access?(user, :profile), do: not is_nil(user)
  def can_access?(user, :signout), do: not is_nil(user)
  def can_access?(user, :signin), do: is_nil(user)
  def can_access?(_user, _id), do: false

  defmacro __using__(home: home) do
    quote do
      @behaviour unquote(__MODULE__)
      import CoreWeb.Menu.Helpers

      @impl true
      def build_menu(%{assigns: assigns}, menu_id, active_item) do
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

        items
        |> Enum.filter(&filter(user, &1))
        |> Enum.map(&builder.(&1))
      end

      defp filter(user, item) do
        cond do
          __MODULE__.can_access?(user, item) -> true
          can_access?(user, item) -> true
          true -> false
        end
      end
    end
  end
end
