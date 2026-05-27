defmodule Systems.Assignment.PaidSlotsHtml do
  @moduledoc """
  Functional components for the paid-slots block on the participants tab.
  All state and event handling live in the parent (ParticipantsView).
  """
  use CoreWeb, :html

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Button
  alias Systems.Assignment.PaidSlotsLogic, as: Helpers

  attr(:entity, :map, required: true)
  attr(:transactions, :list, required: true)
  attr(:add_button, :map, required: true)
  attr(:target, :any, required: true)

  def paid_slots(assigns) do
    ~H"""
    <div>
      <%= unless Enum.empty?(@transactions) do %>
        <div class="text-bodymedium font-body text-grey2">
          <%= dgettext("eyra-assignment", "panl_participants.reward.line",
            reward: Helpers.format_cents(@entity.subject_reward)
          ) %>
        </div>
        <.spacing value="M" />
      <% end %>

      <div class="flex flex-col gap-4 mb-6">
        <%= for transaction <- @transactions do %>
          <.budget_card transaction={transaction} entity={@entity} target={@target} />
        <% end %>

        <%= if Enum.empty?(@transactions) do %>
          <div class="text-bodymedium font-body text-grey2 mb-4">
            <%= dgettext("eyra-assignment", "payment.transactions.empty") %>
          </div>
        <% end %>
      </div>

      <Button.dynamic {@add_button} />
    </div>
    """
  end

  attr(:transaction, :map, required: true)
  attr(:entity, :map, required: true)
  attr(:target, :any, required: true)

  defp budget_card(%{transaction: transaction, entity: entity} = assigns) do
    tag = Helpers.status_tag(transaction.status)
    reward = entity.subject_reward || 0
    assigns = assign(assigns, tag: tag, total: transaction.total_amount, reward: reward)

    ~H"""
    <div data-testid={"transaction-card-#{@transaction.status}"}>
      <Panel.flat>
        <div class="flex items-start justify-between">
          <div>
            <div class="text-title5 font-title5 text-grey1 mb-1">
              <%= dgettext("eyra-assignment", "panl_participants.payment_prefix") %> <%= @transaction.invoice_id %>
            </div>
            <div class="text-bodysmall font-body text-grey2">
              <%= Helpers.format_cents(@total) %> | <%= Helpers.budget_description(@transaction.subject_count, @reward) %>
            </div>
          </div>
          <.status_element transaction={@transaction} tag={@tag} target={@target} />
        </div>
      </Panel.flat>
    </div>
    """
  end

  attr(:transaction, :map, required: true)
  attr(:tag, :map, required: true)
  attr(:target, :any, required: true)

  defp status_element(%{transaction: %{status: :pending}} = assigns) do
    ~H"""
    <button
      type="button"
      phx-click="resume_payment"
      phx-value-provider-uid={@transaction.transaction_id}
      phx-target={@target}
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
