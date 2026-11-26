defmodule Systems.License.NextActions do
  @moduledoc """
  The To-dos that show the notifications about a user's license
  (`License.Notify`): `Given` when support gives it or gives it again,
  `SwitchedOff` when support switches it off, `Reminder` from 14 days before
  its end date, and `Ended` once its end date has passed. Their params are the
  notification's metadata (`"license"`, `"valid_until"`). A user has at most
  one of them per license: each new one marks the earlier ones seen
  (`License.Public.tell_current/3`). Clicking the button opens the notification, which
  marks it seen and clears the To-do (`Notify.Public.open_action/2`).
  """
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License

  @doc "The license of a To-do's params."
  def license(%{"license" => "publish"}), do: :publish
  def license(%{"license" => "pay_in"}), do: :pay_in

  @doc "The name of `license` in a To-do."
  def name(:publish), do: dgettext("eyra-nextaction", "license.publish")
  def name(:pay_in), do: dgettext("eyra-nextaction", "license.pay_in")

  @doc "An end date in a To-do's params, written as `License.Public.format_date/1` does."
  def format_date(iso_date), do: iso_date |> Date.from_iso8601!() |> License.Public.format_date()
end
