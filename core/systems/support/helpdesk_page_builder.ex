defmodule Systems.Support.HelpdeskPageBuilder do
  import CoreWeb.Gettext

  def view_model(user, _assigns) do
    %{
      title: dgettext("eyra-support", "form.title"),
      user: user,
      active_menu_item: :helpdesk
    }
  end
end
