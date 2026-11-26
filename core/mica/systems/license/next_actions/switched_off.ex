defmodule Systems.License.NextActions.SwitchedOff do
  @moduledoc """
  The To-do that tells a user support switched off one of their licenses:
  what is refused now, that running studies keep running, and that they can
  ask support through the helpdesk page.
  """
  @behaviour Systems.NextAction.ViewModel
  use MicaWeb, :verified_routes
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License.NextActions

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"license" => key}) do
    license = NextActions.license(key)

    %{
      title:
        dgettext("eyra-nextaction", "license.switched_off.title",
          license: NextActions.name(license)
        ),
      description: description(license),
      cta_label: dgettext("eyra-nextaction", "license.helpdesk.cta"),
      cta_action: %{type: :redirect, to: ~m"/support/helpdesk"}
    }
  end

  defp description(:publish),
    do: dgettext("eyra-nextaction", "license.switched_off.publish.description")

  defp description(:pay_in),
    do: dgettext("eyra-nextaction", "license.switched_off.pay_in.description")
end
