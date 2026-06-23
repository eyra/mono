defmodule Systems.Account.PayoutsViewBuilder do
  @moduledoc """
  Builds the view model for the "Uitbetalingen" (payouts) tab:

    * `bank` — the bank-account verification status (a colored badge + an action
      button), derived live from OPP via `Fund.Public.verification_status/1`.
    * `overview` — the payout history grouped by year (`Fund.Public.list_payouts_for_user/1`),
      with a per-year total. The view picks the rows for the selected year.

  All i18n lives here; `PayoutsView` only renders the supplied strings.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.ConfirmationModal
  alias Systems.Account
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Fund

  def view_model(%Account.User{} = user, _assigns) do
    %{
      title: dgettext("eyra-account", "payouts.title"),
      bank: build_bank(Fund.Public.verification_status(user)),
      overview: build_overview(Fund.Public.list_payouts_for_user(user))
    }
  end

  @doc """
  Confirmation modal for the "Toevoegen" action. Confirming hands the participant
  off (`http_get`) to OPP's hosted verification page, where OPP's own iDEAL flow
  lets them pick their bank — so we keep no bank list of our own.
  """
  def bank_verification_modal(verification_url) when is_binary(verification_url) do
    LiveNest.Modal.prepare_live_component(
      "bank_verification",
      ConfirmationModal,
      params: [
        assigns: %{
          title: dgettext("eyra-account", "payouts.bank.modal.title"),
          body: dgettext("eyra-account", "payouts.bank.modal.body"),
          confirm_label: dgettext("eyra-account", "payouts.bank.modal.confirm"),
          cancel_label: dgettext("eyra-ui", "cancel.button"),
          confirm_action: %{type: :http_get, to: verification_url}
        }
      ],
      style: :compact
    )
  end

  defp build_bank(status) do
    %{
      title: dgettext("eyra-account", "payouts.bank.title"),
      intro: dgettext("eyra-account", "payouts.bank.intro"),
      status: status,
      status_label: status_label(status),
      status_variant: status_variant(status),
      button: bank_button(status),
      merchant_url: merchant_url(status)
    }
  end

  # :info (green), :warning (orange), :error (red) — maps to Pixel.Status.*
  # `:merchant_blocked` means the participant has started OPP onboarding and the
  # merchant KYC is under way — that reads as in-progress (orange), not red.
  defp status_variant(:verified), do: :info
  defp status_variant(:pending), do: :warning
  defp status_variant({:merchant_blocked, _url}), do: :warning
  defp status_variant(_status), do: :error

  defp status_label(:verified), do: dgettext("eyra-account", "payouts.bank.status.verified")

  defp status_label({:merchant_blocked, _url}),
    do: dgettext("eyra-account", "payouts.bank.status.action_required")

  defp status_label(:pending), do: dgettext("eyra-account", "payouts.bank.status.pending")
  defp status_label(_status), do: dgettext("eyra-account", "payouts.bank.status.not_verified")

  defp bank_button(:verified),
    do: send_button("manage", :secondary, dgettext("eyra-account", "payouts.bank.button.manage"))

  # Under review at OPP — no manual action; the badge updates reactively (webhook
  # + slow poll), so there is no "check status" button.
  defp bank_button(:pending), do: nil

  # OPP still needs something from the participant to finish merchant KYC; the
  # button takes them back there to complete the remaining steps.
  defp bank_button({:merchant_blocked, url}),
    do: link_button(url, dgettext("eyra-account", "payouts.bank.button.continue"))

  defp bank_button(_status),
    do:
      send_button(
        "start_verification",
        :primary,
        dgettext("eyra-account", "payouts.bank.button.add")
      )

  defp send_button(event, face_type, label) do
    %{
      action: %{type: :send, event: event},
      face: %{type: face_type, label: label}
    }
  end

  defp link_button(url, label) do
    %{
      action: %{type: :http_get, to: url},
      face: %{type: :secondary, label: label}
    }
  end

  defp merchant_url({:merchant_blocked, url}), do: url
  defp merchant_url(_status), do: nil

  defp build_overview([]) do
    base_overview()
    |> Map.merge(%{empty?: true, years: [], rows_by_year: %{}, totals_by_year: %{}})
  end

  defp build_overview(payouts) do
    by_year = Enum.group_by(payouts, &payout_year/1)
    years = by_year |> Map.keys() |> Enum.sort(:desc)

    base_overview()
    |> Map.merge(%{
      empty?: false,
      years: years,
      rows_by_year:
        Map.new(by_year, fn {year, list} -> {year, Enum.map(list, &payout_row/1)} end),
      totals_by_year: Map.new(by_year, fn {year, list} -> {year, format_total(list)} end)
    })
  end

  defp base_overview do
    %{
      title: dgettext("eyra-account", "payouts.overview.title"),
      intro: dgettext("eyra-account", "payouts.overview.intro"),
      empty_message: dgettext("eyra-account", "payouts.overview.empty"),
      total_label: dgettext("eyra-account", "payouts.overview.total"),
      table_headers: table_headers()
    }
  end

  defp table_headers do
    [
      dgettext("eyra-account", "payouts.table.date"),
      dgettext("eyra-account", "payouts.table.amount"),
      dgettext("eyra-account", "payouts.table.status")
    ]
  end

  defp payout_year(%Fund.PayoutModel{inserted_at: inserted_at}), do: inserted_at.year

  # A table row is the list of cell values; the column types live in the layout.
  # The status cell is a `:tag` chip (text + colors), matching the pay-in chips.
  defp payout_row(%Fund.PayoutModel{
         inserted_at: inserted_at,
         amount_cents: amount_cents,
         status: status
       }) do
    [
      format_date(inserted_at),
      CurrencyHelpers.format_cents(amount_cents),
      payout_status_tag(status)
    ]
  end

  defp format_date(%NaiveDateTime{} = inserted_at),
    do: Calendar.strftime(inserted_at, "%d - %m - %Y")

  defp format_total(payouts) do
    payouts
    |> Enum.reduce(0, fn %Fund.PayoutModel{amount_cents: cents}, acc -> acc + cents end)
    |> CurrencyHelpers.format_cents()
  end

  # Same chip colors as the researcher-side pay-in status (Assignment.PaidSlotsLogic).
  defp payout_status_tag(:completed) do
    %{
      text: dgettext("eyra-account", "payouts.status.completed"),
      bg_color: "bg-success",
      text_color: "text-success"
    }
  end

  defp payout_status_tag(:pending) do
    %{
      text: dgettext("eyra-account", "payouts.status.pending"),
      bg_color: "bg-warning",
      text_color: "text-warning"
    }
  end

  defp payout_status_tag(:failed) do
    %{
      text: dgettext("eyra-account", "payouts.status.failed"),
      bg_color: "bg-deletelight",
      text_color: "text-delete"
    }
  end
end
