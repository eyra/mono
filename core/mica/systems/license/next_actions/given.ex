defmodule Systems.License.NextActions.Given do
  @moduledoc "The To-do that tells a user support gave them a license, and until when."
  @behaviour Systems.NextAction.ViewModel
  use MicaWeb, :verified_routes
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License.NextActions

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"license" => key, "valid_until" => valid_until}) do
    license = NextActions.license(key)

    %{
      title:
        dgettext("eyra-nextaction", "license.given.title",
          license: NextActions.name(license),
          date: NextActions.format_date(valid_until)
        ),
      description: description(license),
      cta_label: dgettext("eyra-nextaction", "license.given.cta"),
      cta_action: %{type: :redirect, to: ~m"/project"}
    }
  end

  defp description(:publish), do: dgettext("eyra-nextaction", "license.given.publish.description")
  defp description(:pay_in), do: dgettext("eyra-nextaction", "license.given.pay_in.description")
end
