defmodule Systems.Assignment.LandingPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(%{info: info}, _assigns) do
    %{
      title: info.title,
      description: info.subtitle || dgettext("eyra-assignment", "landing.description.default"),
      continue_button: dgettext("eyra-assignment", "landing.continue.button")
    }
  end
end
