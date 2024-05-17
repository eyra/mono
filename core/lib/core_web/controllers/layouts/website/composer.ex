defmodule CoreWeb.Layouts.Website.Composer do
  defmacro __using__(_) do
    quote do
      use CoreWeb.LiveMenus, {
        :website_menu_builder,
        [
          :mobile_menu,
          :mobile_navbar,
          :desktop_navbar
        ]
      }

      use CoreWeb.UI.PlainDialog

      import CoreWeb.Layouts.Website.Composer
      import CoreWeb.Layouts.Website.Html
    end
  end
end
