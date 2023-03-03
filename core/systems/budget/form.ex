defmodule Systems.Budget.Form do
  use CoreWeb.UI.LiveComponent

  require Logger

  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.Dropdown
  alias Frameworks.Pixel.Form.{Form, TextInput}
  alias Frameworks.Pixel.Text.{Title3, FormFieldLabel}

  alias Systems.{
    Budget
  }

  prop(budget, :any)
  prop(user, :any)
  prop(locale, :any)
  prop(target, :any)

  data(title, :string)
  data(buttons, :list)

  data(changeset, :map)
  data(validate_changeset?, :boolean)

  data(currencies, :list)
  data(currency_selector, :map)
  data(selected_currency, :map)

  # Selector toggle
  def update(%{selector: :toggle}, socket) do
    {
      :ok,
      socket |> assign(currency_error: nil)
    }
  end

  # Selector selected
  def update(
        %{selector: :selected, option: %{id: id}},
        %{assigns: %{currencies: currencies}} = socket
      ) do
    selected_currency = currencies |> Enum.find(&(&1.id == id))

    {
      :ok,
      socket
      |> assign(selected_currency: selected_currency)
    }
  end

  # Initial update create
  def update(%{id: id, budget: nil, user: user, locale: locale, target: target}, socket) do
    title = dgettext("eyra-budget", "budget.create.title")
    budget = %Budget.Model{}
    changeset = Budget.Model.prepare(budget)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        user: user,
        locale: locale,
        budget: budget,
        changeset: changeset,
        validate_changeset?: false
      )
      |> update_currencies()
      |> init_buttons()
      |> init_currency_selector()
    }
  end

  # Initial update edit
  def update(%{id: id, budget: budget, user: user, locale: locale, target: target}, socket) do
    title = dgettext("eyra-budget", "budget.edit.title")
    changeset = Budget.Model.prepare(budget)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        user: user,
        locale: locale,
        budget: budget,
        changeset: changeset,
        validate_changeset?: true
      )
      |> update_currencies()
      |> init_buttons()
      |> init_currency_selector()
    }
  end

  defp update_currencies(socket) do
    currencies =
      Budget.Public.list_bank_accounts(currency: Budget.CurrencyModel.preload_graph(:full))
      |> Enum.map(& &1.currency)

    socket |> assign(currencies: currencies)
  end

  defp init_currency_selector(%{assigns: %{budget: %{currency: %{id: _id}}}} = socket) do
    socket |> assign(currency_selector: nil, selected_currency: nil)
  end

  defp init_currency_selector(%{assigns: %{currencies: [currency]}} = socket) do
    socket |> assign(currency_selector: nil, selected_currency: currency)
  end

  defp init_currency_selector(
         %{assigns: %{id: id, locale: locale, currencies: currencies}} = socket
       ) do
    {currency_selector, selected_currency} =
      Budget.Presenter.init_currency_selector(currencies, locale, %{type: __MODULE__, id: id})

    socket |> assign(currency_selector: currency_selector, selected_currency: selected_currency)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :submit},
          face: %{type: :primary, label: dgettext("eyra-budget", "budget.submit.button")}
        },
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
      socket |> change(attrs)
    }
  end

  @impl true
  def handle_event("submit", %{"model" => attrs}, socket) do
    {:noreply, socket |> submit(attrs)}
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: "cancel"})
    {:noreply, socket}
  end

  defp change(
         %{assigns: %{budget: budget, validate_changeset?: validate_changeset?}} = socket,
         attrs
       ) do
    socket
    |> apply_change(
      budget
      |> Budget.Model.change(attrs)
      |> Budget.Model.validate(validate_changeset?)
    )
  end

  defp apply_change(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :change) do
      {:ok, _budget} -> socket |> assign(changeset: changeset)
      {:error, changeset} -> socket |> assign(changeset: changeset)
    end
  end

  defp submit(%{assigns: %{budget: %{currency: %{id: _id}} = budget}} = socket, attrs) do
    # Edit modus
    socket
    |> apply_submit(
      budget
      |> Budget.Model.change(attrs)
      |> Budget.Model.validate()
      |> Budget.Model.submit()
    )
  end

  defp submit(
         %{assigns: %{budget: budget, user: user, selected_currency: selected_currency}} = socket,
         attrs
       ) do
    # Create modus
    socket
    |> apply_submit(
      budget
      |> Budget.Model.change(attrs)
      |> Budget.Model.validate()
      |> Budget.Model.submit(user, selected_currency)
    )
  end

  defp apply_submit(%{assigns: %{target: target}} = socket, changeset) do
    case EctoHelper.upsert(changeset) do
      {:ok, _budget} ->
        update_target(target, %{module: __MODULE__, action: "saved"})
        socket

      {:error, changeset} ->
        socket |> assign(changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Title3>
        {@title}
      </Title3>
      <Spacing value="XS" />
      <Form
        id="budget_form"
        changeset={@changeset}
        submit="submit"
        change_event="change"
        target={@myself}
      >
        <TextInput field={:name} debounce="0" label_text={dgettext("eyra-budget", "budget.name.label")} />
        <TextInput
          field={:virtual_icon}
          maxlength="2"
          debounce="0"
          label_text={dgettext("eyra-budget", "budget.icon.label")}
        />

        <div :if={@currency_selector}>
          <FormFieldLabel id={:currency_label}>
            {dgettext("eyra-budget", "budget.currency.label")}
          </FormFieldLabel>
          <Spacing value="XXS" />
          <Dropdown.Selector {...@currency_selector} />
        </div>

        <Spacing value="M" />
        <div class="flex flex-row gap-4">
          <DynamicButton :for={button <- @buttons} vm={button} />
        </div>
      </Form>
    </div>
    """
  end
end
