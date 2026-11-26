defmodule Systems.License.NextActions do
  @moduledoc """
  The To-dos that tell a user about one of their licenses, keyed by the
  license (`"publish"`, `"pay_in"`): `Given` when support gives it or gives
  it again, `SwitchedOff` when support switches it off, and `Reminder` from
  14 days before its end date. A user has at most one of them per license:
  each replaces the others (`License.Public.tell/3`).
  """
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.License

  @types [
    License.NextActions.Given,
    License.NextActions.SwitchedOff,
    License.NextActions.Reminder
  ]

  @doc "The To-do types about a license."
  def types, do: @types

  @doc "The next-action key of `license`."
  def key(license), do: to_string(license)

  @doc "The license of the next-action `key`."
  def license("publish"), do: :publish
  def license("pay_in"), do: :pay_in

  @doc "The name of `license` in a To-do."
  def name(:publish), do: dgettext("eyra-nextaction", "license.publish")
  def name(:pay_in), do: dgettext("eyra-nextaction", "license.pay_in")

  @doc "An end date in a To-do's params, written as `License.Public.format_date/1` does."
  def format_date(iso_date), do: iso_date |> Date.from_iso8601!() |> License.Public.format_date()
end
