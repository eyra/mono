defmodule Systems.Assignment.PaidSlotsLogic do
  @moduledoc """
  Paid-slots concerns mixed into the parent LiveComponent (typically
  ParticipantsView):

    * `use` injects the LiveComponent callbacks (`compose(:budget_form, …)`
      and the paid-slots `handle_event/3` clauses) so the parent gets
      the modal lifecycle and payment-resume flow for free.
    * Public helpers (`assign_paid_slots_state/1`, `list_transactions/1`,
      `format_cents/1`, etc.) are called directly from the parent's
      `update/2` and render.

  All state lives on the parent component's socket; this module owns
  none.
  """

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Budget

  defmacro __using__(_opts) do
    quote do
      require Logger
      import Systems.Assignment.PaidSlotsHtml

      @impl true
      def compose(:budget_form, %{
            assignment: assignment,
            user: user,
            active_currency: active_currency,
            transactions: transactions
          }) do
        %{
          module: Systems.Assignment.BudgetForm,
          params: %{
            assignment: assignment,
            user: user,
            active_currency: active_currency,
            reward_locked?: transactions != []
          }
        }
      end

      @impl true
      def handle_event("add_budget", _, socket) do
        {:noreply,
         socket
         |> compose_child(:budget_form)
         |> show_modal(:budget_form, :compact)}
      end

      @impl true
      def handle_event("budget_form_hide", _, socket) do
        {:noreply, socket |> hide_modal(:budget_form)}
      end

      @impl true
      def handle_event("budget_form_cancelled", _, socket) do
        {:noreply, socket |> hide_modal(:budget_form)}
      end

      @impl true
      def handle_event("budget_form_submit", _, socket) do
        {:noreply,
         socket
         |> Systems.Assignment.PaidSlotsLogic.refresh_assignment()
         |> Systems.Assignment.PaidSlotsLogic.assign_transactions()
         |> hide_modal(:budget_form)}
      end

      @impl true
      def handle_event("resume_payment", %{"provider-uid" => provider_uid}, socket) do
        case Systems.Payment.Public.get_transaction(provider_uid) do
          {:ok, %{payment_url: payment_url}} when is_binary(payment_url) ->
            {:noreply, redirect(socket, external: payment_url)}

          {:ok, _} ->
            Logger.warning("[PaidSlots] No payment_url for transaction #{provider_uid}")

            {:noreply,
             socket
             |> Frameworks.Pixel.Flash.push_error(
               dgettext("eyra-assignment", "panl_participants.resume.error")
             )}

          {:error, error} ->
            Logger.warning("[PaidSlots] Resume payment failed: #{inspect(error)}")

            {:noreply,
             socket
             |> Frameworks.Pixel.Flash.push_error(
               dgettext("eyra-assignment", "panl_participants.resume.error")
             )}
        end
      end
    end
  end

  def assign_paid_slots_state(%{assigns: %{content_flags: %{paid_slots: true}}} = socket) do
    socket
    |> assign_transactions()
    |> assign_active_currency()
    |> assign_add_button()
  end

  def assign_paid_slots_state(socket), do: socket

  def assign_transactions(%{assigns: %{assignment: assignment}} = socket) do
    Phoenix.Component.assign(socket, transactions: list_transactions(assignment))
  end

  def assign_active_currency(%{assigns: %{assignment: assignment}} = socket) do
    Phoenix.Component.assign(socket, active_currency: active_currency(assignment))
  end

  def assign_add_button(%{assigns: %{myself: myself}} = socket) do
    button = %{
      action: %{type: :send, event: "add_budget", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "panl_participants.add.button")
      },
      testid: "pay-add-participants-button"
    }

    Phoenix.Component.assign(socket, add_button: button)
  end

  def refresh_assignment(%{assigns: %{assignment: %{id: id}}} = socket) do
    assignment = Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))
    Phoenix.Component.assign(socket, assignment: assignment, entity: assignment.info)
  end

  def list_transactions(%{fund: nil}), do: []

  def list_transactions(%{fund: fund}) do
    Budget.Public.list_transactions_by_fund(fund)
  end

  def active_currency(%{fund: %{currency_ledger: %{currency: currency}}}), do: currency
  def active_currency(_), do: :EUR

  def format_cents(value), do: CurrencyHelpers.format_cents(value)

  def budget_description(subject_count, subject_reward) do
    dgettext("eyra-assignment", "payment.budget.description",
      count: subject_count || 0,
      reward: format_cents(subject_reward)
    )
  end

  def status_tag(:completed) do
    %{
      text: dgettext("eyra-assignment", "payment.status.paid"),
      bg_color: "bg-success",
      text_color: "text-success"
    }
  end

  def status_tag(:pending) do
    %{
      text: dgettext("eyra-assignment", "payment.status.pending"),
      bg_color: "bg-warning",
      text_color: "text-warning"
    }
  end

  def status_tag(status) when status in [:failed, :expired] do
    %{
      text: dgettext("eyra-assignment", "payment.status.failed"),
      bg_color: "bg-deletelight",
      text_color: "text-delete"
    }
  end
end
