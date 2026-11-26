defmodule Systems.License.NextActions.Reminder do
  @moduledoc """
  The To-do from 14 days before a license's end date: which license ends and
  when, opening the helpdesk page to ask support to extend it. It goes away
  when support gives the license again.
  """
  @behaviour Systems.NextAction.ViewModel
  use MicaWeb, :verified_routes
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License.NextActions
  alias Systems.Notify

  @impl Systems.NextAction.ViewModel
  def to_view_model(_count, %{"valid_until" => valid_until} = params) do
    %{
      title:
        dgettext("eyra-nextaction", "license.reminder.title",
          license: NextActions.name(NextActions.license(params)),
          date: NextActions.format_date(valid_until)
        ),
      description: dgettext("eyra-nextaction", "license.reminder.description"),
      cta_label: dgettext("eyra-nextaction", "license.helpdesk.cta"),
      cta_action: Notify.Public.open_action(params, ~m"/support/helpdesk")
    }
  end
end
