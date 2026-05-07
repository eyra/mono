defmodule Systems.Assignment.PanlParticipantsView do
  use CoreWeb, :live_component

  require Logger

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Button

  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.Budget
  alias Systems.Pool

  @impl true
  def update(
        %{
          id: id,
          assignment: %{info: info} = assignment,
          user: user,
          title: title,
          viewport: viewport,
          breakpoint: breakpoint,
          content_flags: content_flags
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment,
        user: user,
        entity: info,
        title: title,
        viewport: viewport,
        breakpoint: breakpoint,
        content_flags: content_flags
      )
      |> assign_transactions()
      |> assign_pending_payouts()
      |> assign_active_currency()
      |> assign_add_button()
      |> assign_advert_link()
      |> assign_pending_approvals()
    }
  end

  @impl true
  def compose(:budget_form, %{
        assignment: assignment,
        user: user,
        active_currency: active_currency,
        transactions: transactions
      }) do
    %{
      module: Assignment.BudgetForm,
      params: %{
        assignment: assignment,
        user: user,
        active_currency: active_currency,
        reward_locked?: transactions != []
      }
    }
  end

  @impl true
  def compose(:payout_modal, %{assignment: %{id: assignment_id}}) do
    %{
      module: Assignment.PayoutModal,
      params: %{assignment_id: assignment_id}
    }
  end

  @impl true
  def handle_event("add_budget", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:budget_form)
      |> show_modal(:budget_form, :compact)
    }
  end

  @impl true
  def handle_event("open_payout_modal", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:payout_modal)
      |> show_modal(:payout_modal, :compact)
    }
  end

  @impl true
  def handle_event("payout_modal_close", _, socket) do
    {
      :noreply,
      socket
      |> hide_modal(:payout_modal)
      |> refresh_assignment()
      |> assign_pending_approvals()
    }
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
    {
      :noreply,
      socket
      |> refresh_assignment()
      |> assign_transactions()
      |> hide_modal(:budget_form)
    }
  end

  @impl true
  def handle_event("resume_payment", %{"provider-uid" => provider_uid}, socket) do
    case Systems.Payment.Public.get_transaction(provider_uid) do
      {:ok, %{payment_url: payment_url}} when is_binary(payment_url) ->
        {:noreply, redirect(socket, external: payment_url)}

      {:ok, _} ->
        Logger.warning("[PanlParticipantsView] No payment_url for transaction #{provider_uid}")

        {:noreply,
         socket
         |> Frameworks.Pixel.Flash.push_error(
           dgettext("eyra-assignment", "panl_participants.resume.error")
         )}

      {:error, error} ->
        Logger.warning("[PanlParticipantsView] Resume payment failed: #{inspect(error)}")

        {:noreply,
         socket
         |> Frameworks.Pixel.Flash.push_error(
           dgettext("eyra-assignment", "panl_participants.resume.error")
         )}
    end
  end

  @impl true
  def handle_event(
        "create_advert",
        _,
        %{assigns: %{assignment: assignment, user: user}} = socket
      ) do
    socket =
      if pool = Pool.Public.get_panl() do
        Advert.Assembly.create(assignment, user, pool)
        socket
      else
        Logger.error("Panl pool not found")
        Frameworks.Pixel.Flash.push_error(socket, "Panl pool not found")
      end

    {:noreply, socket |> assign_advert_link()}
  end

  defp refresh_assignment(%{assigns: %{assignment: %{id: id}}} = socket) do
    assignment = Assignment.Public.get!(id, Assignment.Model.preload_graph(:down))
    assign(socket, assignment: assignment, entity: assignment.info)
  end

  defp assign_transactions(%{assigns: %{assignment: assignment}} = socket) do
    assign(socket, transactions: list_transactions(assignment))
  end

  defp assign_pending_payouts(socket) do
    assign(socket, pending_payouts: 0)
  end

  defp assign_active_currency(%{assigns: %{assignment: assignment}} = socket) do
    assign(socket, active_currency: get_active_currency(assignment))
  end

  defp assign_add_button(%{assigns: %{myself: myself}} = socket) do
    button = %{
      action: %{type: :send, event: "add_budget", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "panl_participants.add.button")
      },
      testid: "pay-add-participants-button"
    }

    assign(socket, add_button: button)
  end

  defp assign_advert_link(%{assigns: %{assignment: %{adverts: [%{id: advert_id} | _]}}} = socket) do
    assign(socket,
      has_advert?: true,
      advert_path: ~p"/advert/#{advert_id}/content",
      monitor_path: ~p"/assignment/#{socket.assigns.assignment.id}/content"
    )
  end

  defp assign_advert_link(%{assigns: %{assignment: assignment, myself: myself}} = socket) do
    assign(socket,
      has_advert?: false,
      create_advert_button: %{
        action: %{type: :send, event: "create_advert", target: myself},
        face: %{
          type: :primary,
          bg_color: "bg-tertiary",
          text_color: "text-grey1",
          label: dgettext("eyra-assignment", "advert.create.button")
        },
        testid: "create-advert-button"
      },
      monitor_path: ~p"/assignment/#{assignment.id}/content"
    )
  end

  defp list_transactions(%{fund: nil}), do: []

  defp list_transactions(%{fund: fund}) do
    Budget.Public.list_transactions_by_fund(fund)
  end

  defp assign_pending_approvals(%{assigns: %{assignment: assignment}} = socket) do
    assign(socket, pending_approvals: Assignment.Public.list_pending_payouts(assignment))
  end

  defp get_active_currency(%{fund: %{currency_ledger: %{currency: currency}}}), do: currency
  defp get_active_currency(_), do: :EUR

  defp format_cents(value), do: CurrencyHelpers.format_cents(value)

  defp budget_description(subject_count, subject_reward) do
    dgettext("eyra-assignment", "payment.budget.description",
      count: subject_count || 0,
      reward: format_cents(subject_reward)
    )
  end

  defp status_tag(:completed) do
    %{
      text: dgettext("eyra-assignment", "payment.status.paid"),
      bg_color: "bg-success",
      text_color: "text-success"
    }
  end

  defp status_tag(:pending) do
    %{
      text: dgettext("eyra-assignment", "payment.status.pending"),
      bg_color: "bg-warning",
      text_color: "text-warning"
    }
  end

  defp status_tag(status) when status in [:failed, :expired] do
    %{
      text: dgettext("eyra-assignment", "payment.status.failed"),
      bg_color: "bg-deletelight",
      text_color: "text-delete"
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <div class="flex flex-row items-baseline gap-3">
          <Text.title2 margin=""><%= @title %></Text.title2>
          <div class="text-title2 font-title2 text-primary">
            <%= @entity.subject_count || 0 %>
          </div>
        </div>
        <.spacing value="XS" />
        <div class="text-bodymedium font-body text-grey2">
          <%= dgettext("eyra-assignment", "panl_participants.reward.line",
            reward: format_cents(@entity.subject_reward)
          ) %>
        </div>
        <.spacing value="L" />

        <div class="flex flex-col gap-4 mb-6">
          <%= for transaction <- @transactions do %>
            <.budget_card transaction={transaction} entity={@entity} myself={@myself} />
          <% end %>

          <%= if Enum.empty?(@transactions) do %>
            <div class="text-bodymedium font-body text-grey2 mb-4">
              <%= dgettext("eyra-assignment", "payment.transactions.empty") %>
            </div>
          <% end %>
        </div>

        <Button.dynamic {@add_button} />

        <.spacing value="XL" />

        <%= if Enum.any?(@pending_approvals) do %>
          <Text.title3 testid="pending-approvals-title">
            <%= dngettext(
              "eyra-assignment",
              "panl_participants.pending_approvals.title.one",
              "panl_participants.pending_approvals.title.other",
              length(@pending_approvals),
              count: length(@pending_approvals)
            ) %>
          </Text.title3>
          <.spacing value="S" />
          <div data-testid="pending-approvals-cta">
            <Button.dynamic
              action={%{type: :send, event: "open_payout_modal", target: @myself}}
              face={%{
                type: :primary,
                label: dgettext("eyra-assignment", "panl_participants.pending_approvals.open.button")
              }}
              testid="open-payout-modal-button"
            />
          </div>
          <.spacing value="XL" />
        <% end %>

        <%= if @content_flags[:invite_participants] do %>
          <Text.title3><%= dgettext("eyra-assignment", "panl_participants.invite.title") %></Text.title3>
          <.spacing value="S" />
          <%= if @has_advert? do %>
            <Text.body><%= dgettext("eyra-assignment", "panl_participants.invite.has_advert") %></Text.body>
            <.spacing value="S" />
            <div class="flex flex-col gap-2">
              <.nav_link
                label={dgettext("eyra-assignment", "panl_participants.advert.link")}
                to={@advert_path}
                testid="goto-advert-button"
              />
              <.nav_link
                label={dgettext("eyra-assignment", "panl_participants.monitor.link")}
                to={@monitor_path}
                testid="goto-monitor-button"
              />
            </div>
          <% else %>
            <Text.body><%= dgettext("eyra-assignment", "panl_participants.invite.no_advert") %></Text.body>
            <.spacing value="S" />
            <Button.dynamic {@create_advert_button} />
          <% end %>
        <% end %>
      </Area.content>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:to, :string, required: true)
  attr(:testid, :string, default: nil)

  defp nav_link(assigns) do
    ~H"""
    <a href={@to} data-testid={@testid} class="text-primary hover:underline text-bodymedium font-body">
      <%= @label %> &rsaquo;
    </a>
    """
  end

  defp budget_card(%{transaction: transaction, entity: entity} = assigns) do
    tag = status_tag(transaction.status)
    reward = entity.subject_reward || 0
    assigns = assign(assigns, tag: tag, total: transaction.total_amount, reward: reward)

    ~H"""
    <Panel.flat>
      <div class="flex items-start justify-between">
        <div>
          <div class="text-title5 font-title5 text-grey1 mb-1">
            <%= dgettext("eyra-assignment", "panl_participants.payment_prefix") %> <%= @transaction.invoice_id %>
          </div>
          <div class="text-bodysmall font-body text-grey2">
            <%= format_cents(@total) %> | <%= budget_description(@transaction.subject_count, @reward) %>
          </div>
        </div>
        <.status_element transaction={@transaction} tag={@tag} myself={@myself} />
      </div>
    </Panel.flat>
    """
  end

  attr(:transaction, :map, required: true)
  attr(:tag, :map, required: true)
  attr(:myself, :any, required: true)

  defp status_element(%{transaction: %{status: :pending}} = assigns) do
    ~H"""
    <button
      type="button"
      phx-click="resume_payment"
      phx-value-provider-uid={@transaction.transaction_id}
      phx-target={@myself}
      class={"#{@tag.bg_color} #{@tag.text_color} bg-opacity-20 hover:bg-opacity-30 rounded px-3 py-1 text-label font-label cursor-pointer"}
      data-testid="resume-payment-button"
    >
      <%= @tag.text %>
    </button>
    """
  end

  defp status_element(assigns) do
    ~H"""
    <Tag.tag text={@tag.text} bg_color={@tag.bg_color} text_color={@tag.text_color} />
    """
  end
end
