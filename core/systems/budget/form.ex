defmodule Systems.Budget.Form do
  @moduledoc false
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.DropdownSelector
  alias Frameworks.Pixel.Text
  alias Frameworks.Utility.EctoHelper
  alias Systems.Budget

  require Logger

  # Initial update create
  @impl true
  def update(%{id: id, budget: nil, user: user, locale: locale}, socket) do
    title = dgettext("eyra-budget", "budget.create.title")
    budget = %Budget.Model{}
    changeset = Budget.Model.prepare(budget)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        locale: locale,
        budget: budget,
        changeset: changeset,
        validate_changeset?: false
      )
      |> update_currencies()
      |> update_selected_currency()
      |> compose_child(:currency_selector)
      |> init_buttons()
    }
  end

  # Initial update edit
  @impl true
  def update(%{id: id, budget: budget, user: user, locale: locale}, socket) do
    title = dgettext("eyra-budget", "budget.edit.title")
    changeset = Budget.Model.prepare(budget)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        locale: locale,
        budget: budget,
        changeset: changeset,
        validate_changeset?: true
      )
      |> update_currencies()
      |> update_options()
      |> init_buttons()
      |> compose_child(:currency_selector)
    }
  end

  @impl true
  def compose(:currency_selector, %{options: options, selected_currency: selected_currency}) do
    selected_option_index = Enum.find_index(options, &(&1.id == selected_currency.id))

    %{
      module: DropdownSelector,
      params: %{
        options: options,
        selected_option_index: selected_option_index
      }
    }
  end

  defp update_selected_currency(%{assigns: %{budget: %{currency: %{id: _id} = currency}}} = socket) do
    assign(socket, selected_currency: currency)
  end

  defp update_selected_currency(%{assigns: %{currencies: [currency | _]}} = socket) do
    assign(socket, selected_currency: currency)
  end

  defp update_selected_currency(socket) do
    assign(socket, selected_currency: nil)
  end

  defp update_currencies(socket) do
    currencies =
      [currency: Budget.CurrencyModel.preload_graph(:full)]
      |> Budget.Public.list_bank_accounts()
      |> Enum.map(& &1.currency)

    assign(socket, currencies: currencies)
  end

  defp update_options(%{assigns: %{currencies: currencies, locale: locale}} = socket) do
    options =
      Enum.map(currencies, fn currency ->
        %{
          id: currency.id,
          value: Budget.CurrencyModel.title(currency, locale)
        }
      end)

    assign(socket, options: options)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket,
      buttons: [
        %{action: %{type: :submit}, face: %{type: :primary, label: dgettext("eyra-budget", "budget.submit.button")}},
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event("change", %{"model" => attrs}, socket) do
    {
      :noreply,
      change(socket, attrs)
    }
  end

  @impl true
  def handle_event("submit", %{"model" => attrs}, socket) do
    {:noreply, handle_submit(socket, attrs)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, send_event(socket, :parent, "budget_cancelled")}
  end

  @impl true
  def handle_event("dropdown_selected", %{option: %{id: id}}, %{assigns: %{currencies: currencies}} = socket) do
    selected_currency = Enum.find(currencies, &(&1.id == id))
    {:noreply, assign(socket, selected_currency: selected_currency)}
  end

  @impl true
  def handle_event("dropdown_toggle", _payload, socket) do
    {:noreply, assign(socket, currency_error: nil)}
  end

  defp change(%{assigns: %{budget: budget, validate_changeset?: validate_changeset?}} = socket, attrs) do
    apply_change(socket, budget |> Budget.Model.change(attrs) |> Budget.Model.validate(validate_changeset?))
  end

  defp apply_change(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :change) do
      {:ok, _budget} -> assign(socket, changeset: changeset)
      {:error, changeset} -> assign(socket, changeset: changeset)
    end
  end

  defp handle_submit(%{assigns: %{budget: %{currency: %{id: _id}} = budget}} = socket, attrs) do
    # Edit modus
    apply_submit(socket, budget |> Budget.Model.change(attrs) |> Budget.Model.validate() |> Budget.Model.submit())
  end

  defp handle_submit(%{assigns: %{budget: budget, user: user, selected_currency: selected_currency}} = socket, attrs) do
    # Create modus
    apply_submit(
      socket,
      budget |> Budget.Model.change(attrs) |> Budget.Model.validate() |> Budget.Model.submit(user, selected_currency)
    )
  end

  defp apply_submit(socket, changeset) do
    case EctoHelper.upsert(changeset) do
      {:ok, _budget} ->
        send_event(socket, :parent, "budget_saved")

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3>
        <%= @title %>
      </Text.title3>
      <.spacing value="XS" />
      <.form id="budget_form" :let={form} for={@changeset} phx-change="change" phx-submit="submit" phx-target={@myself} >
        <.text_input form={form} field={:name} debounce="0" label_text={dgettext("eyra-budget", "budget.name.label")} />
        <.text_input form={form}
          field={:virtual_icon}
          maxlength="2"
          debounce="0"
          label_text={dgettext("eyra-budget", "budget.icon.label")}
        />

        <%= if @currency_selector do %>
          <Text.form_field_label id={:currency_label}>
            <%= dgettext("eyra-budget", "budget.currency.label") %>
          </Text.form_field_label>
          <.spacing value="XXS" />
          <.child name={:currency_selector} fabric={@fabric} />
        <% end %>

        <.spacing value="M" />
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </.form>
    </div>
    """
  end
end
