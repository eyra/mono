defmodule Systems.Account.PayoutsView do
  @moduledoc """
  Embedded LiveView for the "Uitbetalingen" (payouts) tab.

  Shows the participant's bank-account verification status and payout history:

    * Bankrekening — a colored status badge (`:not_verified` red, `:pending`
      orange, `:verified` green) plus an action button. "Toevoegen" first opens
      an in-platform phone form (`Systems.Account.PhoneForm`) when no phone is
      known — pushing it to OPP via the API avoids a hosted phone-entry redirect.
      With a phone already on file it runs `Fund.Public.start_bank_verification/1`
      and opens a confirmation modal. Either way the participant ends up at OPP's
      hosted iDEAL flow, where OPP lets them pick their bank (we keep no bank list
      of our own).

    * Overzicht — payout history (`Fund.Public.list_payouts_for_user/1`) grouped
      by year, with a year filter and a per-year total.

  The `:pending` badge flips to `:verified` reactively: an OPP `bank_account`
  webhook dispatches `{:payment_kyc, :updated}` which the Observatory broadcast
  re-renders this view (see `Systems.Account.Switch`). A slow poll while pending
  is the fallback for missed webhooks.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Flash
  alias Frameworks.Pixel.Status
  alias Frameworks.Pixel.Table
  alias Frameworks.Pixel.Text
  alias Systems.Account
  alias Systems.Fund

  @poll_interval_ms 30_000

  def dependencies(), do: [:user_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{user_id: user_id}}) do
    Account.Public.get_user!(user_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {
      :ok,
      socket
      |> assign(selected_year: nil)
      |> maybe_schedule_poll()
    }
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event(
        "start_verification",
        _params,
        %{assigns: %{model: %{phone: nil} = user}} = socket
      ) do
    {:noreply, present_modal(socket, Account.PayoutsViewBuilder.phone_form_modal(user))}
  end

  @impl true
  def handle_event("start_verification", _params, %{assigns: %{model: user}} = socket) do
    case Fund.Public.start_bank_verification(user) do
      {:bank, url} when is_binary(url) ->
        {:noreply, present_modal(socket, Account.PayoutsViewBuilder.bank_verification_modal(url))}

      :verified ->
        {:noreply,
         socket
         |> update_view_model()
         |> Flash.push_info(dgettext("eyra-account", "payouts.bank.verified.flash"))}

      {:error, _reason} ->
        {:noreply, Flash.push_error(socket, dgettext("eyra-account", "payouts.bank.error.flash"))}
    end
  end

  @impl true
  def handle_event("select_year", %{"year" => year}, socket) do
    {:noreply, assign(socket, selected_year: String.to_integer(year))}
  end

  # Slow-poll fallback: re-fetch OPP status while the bank account is pending,
  # so the badge flips to "Geverifiëerd" even if the webhook is missed.
  @impl true
  def handle_info(:poll_bank_status, socket) do
    {:noreply, socket |> update_view_model() |> maybe_schedule_poll()}
  end

  defp maybe_schedule_poll(%{assigns: %{vm: %{bank: %{status: :pending}}}} = socket) do
    Process.send_after(self(), :poll_bank_status, @poll_interval_ms)
    socket
  end

  defp maybe_schedule_poll(socket), do: socket

  defp payout_table_layout do
    [
      %{type: :text, width: "w-1/3", align: "text-left"},
      %{type: :text, width: "w-1/3", align: "text-left"},
      %{type: :tag, width: "w-1/3", align: "text-left"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="payouts-view">
      <Area.content>
        <.spacing value="L" />
        <Text.title2><%= @vm.title %></Text.title2>

        <.spacing value="M" />
        <Text.title3><%= @vm.bank.title %></Text.title3>
        <.spacing value="XS" />
        <.bank_status variant={@vm.bank.status_variant} label={@vm.bank.status_label} />
        <.spacing value="S" />
        <Text.body><%= @vm.bank.intro %></Text.body>
        <%= if @vm.bank.button do %>
          <.spacing value="S" />
          <Button.dynamic {@vm.bank.button} />
        <% end %>

        <.spacing value="L" />
        <div class="border-t border-grey4"></div>
        <.spacing value="L" />

        <Text.title3><%= @vm.overview.title %></Text.title3>
        <.spacing value="XS" />
        <Text.body><%= @vm.overview.intro %></Text.body>
        <.spacing value="M" />

        <%= if @vm.overview.empty? do %>
          <Text.body><%= @vm.overview.empty_message %></Text.body>
        <% else %>
          <% selected = @selected_year || List.first(@vm.overview.years) %>
          <div class="flex flex-row flex-wrap gap-3 items-center" data-testid="year-filter">
            <%= for year <- @vm.overview.years do %>
              <button
                type="button"
                phx-click="select_year"
                phx-value-year={year}
                class={[
                  "rounded-full px-6 py-3 text-label font-label select-none",
                  year == selected && "bg-primary text-white",
                  year != selected && "bg-grey5 text-grey2"
                ]}
              >
                <%= year %>
              </button>
            <% end %>
          </div>
          <.spacing value="M" />
          <Text.title4>
            <%= @vm.overview.total_label %>: <%= Map.get(@vm.overview.totals_by_year, selected) %>
          </Text.title4>
          <.spacing value="S" />
          <Table.table
            id="payouts-table"
            layout={payout_table_layout()}
            head_cells={@vm.overview.table_headers}
            rows={Map.get(@vm.overview.rows_by_year, selected, [])}
            border={false}
            top_line?={true}
          />
        <% end %>

        <.spacing value="XL" />
      </Area.content>
    </div>
    """
  end

  attr(:variant, :atom, required: true)
  attr(:label, :string, required: true)

  defp bank_status(%{variant: :info} = assigns), do: ~H"<Status.info text={@label} />"
  defp bank_status(%{variant: :warning} = assigns), do: ~H"<Status.warning text={@label} />"
  defp bank_status(assigns), do: ~H"<Status.error text={@label} />"
end
