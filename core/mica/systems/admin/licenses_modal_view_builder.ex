defmodule Systems.Admin.LicensesModalViewBuilder do
  @moduledoc """
  ViewBuilder for the Licenses dialog (`Systems.Admin.LicensesModalView`).

  One item per license in `License.Public.licenses/0`, each with its state and
  end date, and what support changed in the dialog (`draft`): switched on or
  off, the period picked, a custom date. Each item carries the change saving
  it makes (`change`): `:none`, `{:on, end_date}`, `:off`, or `{:error, reason}`
  when it can't be saved yet. Errors show once support tried to save
  (`show_errors?`).
  """
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Account
  alias Systems.Content
  alias Systems.License
  alias Systems.Org

  def view_model(%Account.User{} = user, assigns) do
    draft = Map.get(assigns, :draft, %{})
    show_errors? = Map.get(assigns, :show_errors?, false)
    locale = Map.get(assigns, :locale, :en)
    today = License.Public.today(Map.get(assigns, :now, DateTime.utc_now()))

    items =
      Enum.map(License.Public.licenses(), fn license ->
        build_item(license, user, Map.get(draft, license, %{}), today, locale, show_errors?)
      end)

    %{
      title: dgettext("eyra-admin", "licenses.title"),
      user_label: "#{Account.User.label(user)} · #{user.email}",
      items: items,
      save_label: dgettext("eyra-admin", "licenses.save"),
      error: save_error(Map.get(assigns, :save_error))
    }
  end

  defp build_item(license, user, draft, today, locale, show_errors?) do
    record =
      License.Public.get_current(user, license, granted_by: [:profile], revoked_by: [:profile])

    active? = record != nil and License.Model.active?(record, today)
    on? = Map.get(draft, :on?, active?)
    period = Map.get(draft, :period)
    custom_date = Map.get(draft, :custom_date, "")
    change = change(on?, active?, period, custom_date, today)

    %{
      id: license,
      label: license_label(license),
      status: status(record, active?, today),
      note: note(record),
      on?: on?,
      select: build_select(on?, active?, record, period, Map.get(draft, :open?, false), today),
      custom?: on? and period == :custom,
      custom_date: custom_date,
      custom_label: dgettext("eyra-admin", "licenses.custom_date.label"),
      min_date: today |> Date.add(1) |> Date.to_iso8601(),
      institutes: institutes(license, user, locale),
      change: change,
      error: if(show_errors?, do: error(change))
    }
  end

  # What saving does with the license.

  defp change(false, true, _period, _custom_date, _today), do: :off
  defp change(false, false, _period, _custom_date, _today), do: :none
  defp change(true, true, nil, _custom_date, _today), do: :none
  defp change(true, false, nil, _custom_date, _today), do: {:error, :no_end_date}

  defp change(true, _active?, :custom, custom_date, today) do
    case Date.from_iso8601(custom_date) do
      {:ok, date} ->
        if Date.after?(date, today), do: {:on, date}, else: {:error, :end_date_not_in_future}

      {:error, _} ->
        {:error, :no_custom_date}
    end
  end

  defp change(true, _active?, period, _custom_date, today),
    do: {:on, License.Public.end_date(period, today)}

  defp error({:error, :no_end_date}), do: dgettext("eyra-admin", "licenses.error.no_end_date")

  defp error({:error, :no_custom_date}),
    do: dgettext("eyra-admin", "licenses.error.no_custom_date")

  defp error({:error, :end_date_not_in_future}),
    do: dgettext("eyra-admin", "licenses.error.end_date_not_in_future")

  defp error(_change), do: nil

  defp save_error(nil), do: nil
  defp save_error(:forbidden), do: dgettext("eyra-admin", "licenses.error.forbidden")
  defp save_error(_reason), do: dgettext("eyra-admin", "licenses.error.not_saved")

  # The license's state and its record.

  defp license_label(:publish), do: dgettext("eyra-admin", "licenses.publish")
  defp license_label(:pay_in), do: dgettext("eyra-admin", "licenses.pay_in")

  defp status(nil, _active?, _today), do: dgettext("eyra-admin", "licenses.status.off")

  defp status(%{valid_until: valid_until}, true, _today),
    do: dgettext("eyra-admin", "licenses.status.on", date: format_date(valid_until))

  defp status(%{revoked_at: nil, valid_until: valid_until}, false, _today),
    do: dgettext("eyra-admin", "licenses.status.ended", date: format_date(valid_until))

  defp status(_record, false, _today), do: dgettext("eyra-admin", "licenses.status.off")

  defp note(nil), do: nil

  defp note(%{revoked_at: nil, granted_at: granted_at, granted_by: granted_by}) do
    dgettext("eyra-admin", "licenses.note.granted",
      name: by_name(granted_by),
      date: format_date(granted_at)
    )
  end

  defp note(%{revoked_at: revoked_at, revoked_by: revoked_by}) do
    dgettext("eyra-admin", "licenses.note.revoked",
      name: by_name(revoked_by),
      date: format_date(revoked_at)
    )
  end

  defp by_name(%Account.User{} = user), do: Account.User.label(user)
  defp by_name(_), do: dgettext("eyra-admin", "licenses.note.no_one")

  # The end date: a period or a custom date. Shown while the license is on.

  defp build_select(false, _active?, _record, _period, _open?, _today), do: nil

  defp build_select(true, active?, record, period, open?, today) do
    options = License.Public.periods() ++ [:custom]

    %{
      label: dgettext("eyra-admin", "licenses.end_date.label"),
      value: select_value(period, active?, record, today),
      placeholder?: period == nil,
      open?: open?,
      options:
        Enum.map(options, fn option ->
          %{id: option, label: period_label(option, today), selected?: option == period}
        end)
    }
  end

  defp select_value(nil, true, %{valid_until: valid_until}, _today),
    do: dgettext("eyra-admin", "licenses.end_date.keep", date: format_date(valid_until))

  defp select_value(nil, false, _record, _today),
    do: dgettext("eyra-admin", "licenses.end_date.choose")

  defp select_value(period, _active?, _record, today), do: period_label(period, today)

  defp period_label(:custom, _today), do: dgettext("eyra-admin", "licenses.period.custom")

  defp period_label(period, today) do
    dgettext("eyra-admin", "licenses.period.until",
      period: period_name(period),
      date: format_date(License.Public.end_date(period, today))
    )
  end

  defp period_name(:days_30), do: dgettext("eyra-admin", "licenses.period.days_30")
  defp period_name(:days_60), do: dgettext("eyra-admin", "licenses.period.days_60")
  defp period_name(:days_90), do: dgettext("eyra-admin", "licenses.period.days_90")
  defp period_name(:year_1), do: dgettext("eyra-admin", "licenses.period.year_1")

  # Pay-in rests on membership of a research institute, so only its item names
  # the researcher's institute, or warns that they have none.

  defp institutes(:pay_in, user, locale) do
    case Org.Public.list_research_institutes(user, Org.NodeModel.preload_graph(:full)) do
      [] ->
        %{
          names: nil,
          warning: dgettext("eyra-admin", "licenses.institute.none"),
          note: dgettext("eyra-admin", "licenses.institute.none.note")
        }

      orgs ->
        names =
          Enum.map_join(orgs, ", ", &Content.TextBundleModel.text(&1.full_name_bundle, locale))

        %{
          names: dgettext("eyra-admin", "licenses.institute.names", names: names),
          warning: nil,
          note: nil
        }
    end
  end

  defp institutes(_license, _user, _locale), do: nil

  defp format_date(%DateTime{} = datetime),
    do: datetime |> License.Public.today() |> format_date()

  defp format_date(%Date{} = date),
    do: date |> Timex.format!("%e %b %Y", :strftime) |> String.trim()
end
