defmodule Systems.Support.HelpdeskPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(user, _assigns) do
    %{
      title: dgettext("eyra-support", "form.title"),
      user: user,
      active_menu_item: :helpdesk,
      first: %{
        description: dgettext("eyra-support", "form.description")
      },
      next: %{
        description: dgettext("eyra-support", "form.description.next"),
        button: %{
          action: %{type: :send, event: "next"},
          face: %{
            type: :secondary,
            label: dgettext("eyra-support", "form.next.button")
          }
        }
      }
    }
  end
end
