defmodule Systems.Citizen.Pool.Form do
  use CoreWeb, :live_component

  require Logger

  import Frameworks.Pixel.Form
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.DropdownSelector
  alias Frameworks.Pixel.Text

  alias Systems.Budget
  alias Systems.Pool

  @default_values %{"director" => "citizen", "target" => 0}

  # Successive update - ignore if already initialized
  @impl true
  def update(_, %{assigns: %{pool: _pool}} = socket) do
    {:ok, socket}
  end

  # Initial update create
  @impl true
  def update(%{id: id, pool: nil, user: user, locale: locale}, socket) do
    title = dgettext("link-citizen", "pool.create.title")

    pool = %Pool.Model{}
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        locale: locale,
        pool: pool,
        changeset: changeset,
        validate_changeset?: false
      )
      |> update_currencies()
      |> update_selected_currency()
      |> update_options()
      |> init_buttons()
    }
  end

  # Initial update edit
  @impl true
  def update(%{id: id, pool: pool, user: user, locale: locale}, socket) do
    title = dgettext("link-citizen", "pool.edit.title")
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        locale: locale,
        pool: pool,
        changeset: changeset,
        validate_changeset?: true
      )
      |> update_currencies()
      |> update_selected_currency()
      |> update_options()
      |> init_buttons()
    }
  end

  defp update_currencies(socket) do
    currencies = Budget.Public.list_currencies_by_type(:legal)
    socket |> assign(currencies: currencies)
  end

  defp update_options(%{assigns: %{currencies: currencies, locale: locale}} = socket) do
    options =
      Enum.map(currencies, fn currency ->
        %{
          id: currency.id,
          label: Budget.CurrencyModel.title(currency, locale)
        }
      end)

    socket |> assign(options: options)
  end

  defp update_selected_currency(%{assigns: %{pool: %{currency: %{id: _id} = currency}}} = socket) do
    socket |> assign(selected_currency: currency)
  end

  defp update_selected_currency(%{assigns: %{currencies: [currency | _]}} = socket) do
    socket |> assign(selected_currency: currency)
  end

  defp update_selected_currency(socket) do
    socket |> assign(selected_currency: nil)
  end

  defp selected_option_index(%{options: options, selected_currency: nil}) do
    if Enum.empty?(options), do: nil, else: 0
  end

  defp selected_option_index(%{options: options, selected_currency: selected_currency}) do
    Enum.find_index(options, &(&1.id == selected_currency.id)) || 0
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
  def handle_event("submit", %{"model" => attrs}, socket) do
    attrs = Map.merge(@default_values, attrs)

    {
      :noreply,
      socket |> handle_submit(attrs)
    }
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> send_event(:parent, "cancelled")}
  end

  @impl true
  def handle_event(
        "dropdown_selected",
        %{option: %{id: id}},
        %{assigns: %{currencies: currencies}} = socket
      ) do
    selected_currency = currencies |> Enum.find(&(&1.id == id))
    {:noreply, socket |> assign(selected_currency: selected_currency)}
  end

  @impl true
  def handle_event("dropdown_toggle", _payload, socket) do
    {:noreply, socket |> assign(currency_error: nil)}
  end

  defp handle_submit(%{assigns: %{pool: %{currency: %{id: _id}} = pool}} = socket, attrs) do
    # Edit modus
    socket
    |> apply_submit(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate()
      |> Pool.Model.submit()
    )
  end

  defp handle_submit(
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

  defp apply_submit(socket, changeset) do
    case EctoHelper.upsert_and_dispatch(changeset, :pool) do
      {:ok, _pool} ->
        socket |> send_event(:parent, "saved")

      {:error, changeset} ->
        socket |> assign(changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= @title %></Text.title3>
      <.spacing value="XS" />
      <.form id="citizen_form" :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.text_input form={form} field={:name} debounce="0" label_text={dgettext("link-citizen", "pool.name.label")} />
        <.text_input form={form}
          field={:virtual_icon}
          debounce="0"
          maxlength="2"
          label_text={dgettext("link-citizen", "pool.icon.label")}
        />

        <Text.form_field_label id={:currency_label}>
          <%= dgettext("link-citizen", "pool.currency.label") %>
        </Text.form_field_label>
        <.spacing value="XXS" />
        <.live_component
          id={:currency_selector}
          module={DropdownSelector}
          options={@options}
          selected_option_index={selected_option_index(assigns)}
          background={:light}
          debounce={0}
        />

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
