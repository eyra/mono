defmodule Systems.Pool.LandingPageBuilder do
  import CoreWeb.Gettext
  alias Systems.Pool

  def view_model(pool, %{current_user: user} = assigns) do
    %{
      pool: pool,
      title: Pool.Model.title(pool),
      description: get_description(pool, user),
      buttons: get_buttons(assigns),
      active_menu_item: nil
    }
  end

  defp get_buttons(%{participant?: true}) do
    [
      %{
        action: %{type: :send, event: "unregister"},
        face: %{type: :primary, label: dgettext("eyra-pool", "landing.unregister.button")}
      }
    ]
  end

  defp get_buttons(%{participant?: false}) do
    [
      %{
        action: %{type: :send, event: "register"},
        face: %{type: :primary, label: dgettext("eyra-pool", "landing.register.button")}
      }
    ]
  end

  defp get_description(pool, user) do
    if Pool.Public.participant?(pool, user) do
      dgettext("eyra-pool", "landing.description.participant")
    else
      dgettext("eyra-pool", "landing.description.visitor")
    end
  end
end
