defmodule Systems.License.NextActions.Ended do
  @moduledoc """
  The To-do once a license's end date has passed: which license ended and
  when, what is refused now, that running studies keep running, and that
  they can ask support through the helpdesk page. It replaces the reminder.
  """
  @behaviour Systems.NextAction.ViewModel
  use MicaWeb, :verified_routes
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License.NextActions
  alias Systems.Notify

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"valid_until" => valid_until} = params) do
    license = NextActions.license(params)

    %{
      title:
        dgettext("eyra-nextaction", "license.ended.title", license: NextActions.name(license)),
      description: description(license, NextActions.format_date(valid_until)),
      cta_label: dgettext("eyra-nextaction", "license.helpdesk.cta"),
      cta_action: Notify.Public.open_action(params, ~m"/support/helpdesk")
    }
  end

  defp description(:publish, date),
    do: dgettext("eyra-nextaction", "license.ended.publish.description", date: date)

  defp description(:pay_in, date),
    do: dgettext("eyra-nextaction", "license.ended.pay_in.description", date: date)
end
