defmodule CoreWeb.Menu.Items do
  import CoreWeb.Gettext

  @items %{
    eyra: %{target: CoreWeb.Index, size: :large},
    dashboard: %{target: Link.Dashboard},
    marketplace: %{target: Link.Dashboard},
    inbox: %{target: Link.Dashboard},
    payments: %{target: Link.Dashboard},
    settings: %{target: CoreWeb.User.Settings},
    profile: %{target: CoreWeb.User.Profile},
    signout: %{target: :delete},
    signin: %{target: :new},
    menu: %{target: "mobile_menu = !mobile_menu"}
  }

  def items(), do: @items

  def item(item_id), do: @items[item_id]

  defmacro __using__(_opts) do
    quote do
      import CoreWeb.Gettext

      unquote(
        for {item_id, _} <- CoreWeb.Menu.Items.items() do
          quote do
            dgettext("eyra-ui", unquote("menu.item.#{item_id}"))
          end
        end
      )

      def info(item_id) do
        CoreWeb.Menu.Items.item(item_id)
      end

      def title(item_id) do
        Gettext.dgettext(CoreWeb.Gettext, "eyra-ui", "menu.item.#{item_id}")
      end
    end
  end
end
