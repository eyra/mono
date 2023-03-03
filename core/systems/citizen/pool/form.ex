defmodule Systems.Citizen.Pool.Form do
  use CoreWeb.UI.LiveComponent

  require Logger

  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.Dropdown
  alias Frameworks.Pixel.Form.{Form, TextInput}
  alias Frameworks.Pixel.Text.{Title3, FormFieldLabel}

  alias Systems.{
    Budget,
    Pool
  }

  @default_values %{"director" => "citizen", "target" => 0}

  prop(pool, :any)
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
  def update(%{id: id, pool: nil, user: user, locale: locale, target: target}, socket) do
    title = dgettext("link-citizen", "pool.create.title")

    pool = %Pool.Model{}
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        pool: nil,
        user: user,
        locale: locale,
        pool: pool,
        changeset: changeset,
        validate_changeset?: false
      )
      |> update_currencies()
      |> init_buttons()
      |> init_currency_selector()
    }
  end

  # Initial update edit
  def update(%{id: id, pool: pool, user: user, locale: locale, target: target}, socket) do
    title = dgettext("link-citizen", "pool.edit.title")
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        user: user,
        locale: locale,
        pool: pool,
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

  defp init_currency_selector(%{assigns: %{pool: %{currency: %{id: _id}}}} = socket) do
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
          face: %{type: :primary, label: dgettext("link-citizen", "pool.submit.button")}
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
    attrs = Map.merge(@default_values, attrs)

    {
      :noreply,
      socket |> submit(attrs)
    }
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: "cancel"})
    {:noreply, socket}
  end

  defp change(%{assigns: %{pool: pool, validate_changeset?: validate_changeset?}} = socket, attrs) do
    socket
    |> apply_change(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate(validate_changeset?)
    )
  end

  defp apply_change(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :change) do
      {:ok, _pool} -> socket |> assign(changeset: changeset)
      {:error, changeset} -> socket |> assign(changeset: changeset)
    end
  end

  defp submit(%{assigns: %{pool: %{currency: %{id: _id}} = pool}} = socket, attrs) do
    # Edit modus
    socket
    |> apply_submit(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate()
      |> Pool.Model.submit()
    )
  end

  defp submit(
         %{assigns: %{pool: pool, user: user, selected_currency: selected_currency}} = socket,
         attrs
       ) do
    # Create modus
    socket
    |> apply_submit(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate()
      |> Pool.Model.submit(user, selected_currency)
    )
  end

  defp apply_submit(%{assigns: %{target: target}} = socket, changeset) do
    case EctoHelper.upsert(changeset) do
      {:ok, _pool} ->
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
      <Title3>{@title}</Title3>
      <Spacing value="XS" />
      <Form id="citizen_form" changeset={@changeset} submit="submit" target={@myself}>
        <TextInput field={:name} debounce="0" label_text={dgettext("link-citizen", "pool.name.label")} />
        <TextInput
          field={:virtual_icon}
          debounce="0"
          maxlength="2"
          label_text={dgettext("link-citizen", "pool.icon.label")}
        />

        <div :if={@currency_selector}>
          <FormFieldLabel id={:currency_label}>
            {dgettext("link-citizen", "pool.currency.label")}
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
