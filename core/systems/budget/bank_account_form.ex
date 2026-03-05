defmodule Systems.Budget.BankAccountForm do
  @moduledoc false
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form
  import Systems.Content.TextBundleInput

  alias Budget.BankAccountModel, as: Model
  alias Ecto.Changeset
  alias Frameworks.Pixel.Text
  alias Frameworks.Utility.EctoHelper
  alias Systems.Budget
  alias Systems.Content

  # Successive update

  @impl true
  def update(_, %{assigns: %{node: _node}} = socket) do
    {
      :ok,
      socket
    }
  end

  # Initial edit update
  @impl true
  def update(%{id: id, bank_account: nil, user: user}, socket) do
    title = dgettext("eyra-budget", "bank.account.create.title")
    bank_account = %Model{}

    changeset = Model.prepare(bank_account)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        bank_account: bank_account,
        changeset: changeset,
        validate_changeset?: false
      )
      |> init_buttons()
    }
  end

  # Initial edit update
  @impl true
  def update(%{id: id, bank_account: bank_account, user: user}, socket) do
    title = dgettext("eyra-budget", "bank.account.edit.title")
    changeset = Model.prepare(bank_account)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        bank_account: bank_account,
        changeset: changeset,
        validate_changeset?: true
      )
      |> init_buttons()
    }
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket,
      buttons: [
        %{
          action: %{type: :submit, target: myself},
          face: %{type: :primary, label: dgettext("eyra-budget", "bank.account.submit.button")}
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event("change", %{"bank_account_model" => attrs}, socket) do
    {
      :noreply,
      change(socket, attrs)
    }
  end

  @impl true
  def handle_event("submit", %{"bank_account_model" => attrs}, socket) do
    {:noreply, handle_submit(socket, attrs)}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, send_event(socket, :parent, "cancelled")}
  end

  defp change(%{assigns: %{bank_account: bank_account, validate_changeset?: validate_changeset?}} = socket, attrs) do
    apply_change(socket, bank_account |> Model.change(attrs) |> Model.validate(validate_changeset?))
  end

  defp apply_change(socket, changeset) do
    case Changeset.apply_action(changeset, :change) do
      {:ok, _bank_account} -> assign(socket, changeset: changeset)
      {:error, changeset} -> assign(socket, changeset: changeset)
    end
  end

  defp handle_submit(%{assigns: %{bank_account: bank_account}} = socket, attrs) do
    apply_submit(socket, bank_account |> Model.change(attrs) |> Model.validate() |> Model.submit())
  end

  defp apply_submit(socket, changeset) do
    case EctoHelper.upsert_and_dispatch(changeset, :bank_account) do
      {:ok, _bank_account} ->
        send_event(socket, :parent, "saved")

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= dgettext("eyra-budget", "bank.account.content.title") %></Text.title3>
      <.form id="bank_account_form" :let={form} for={@changeset} phx-change="change" phx-submit="submit" phx-target={@myself} >

      <.text_input form={form}
        field={:name}
        debounce="0"
        label_text={dgettext("eyra-budget", "bank.account.name.label")}
      />
      <.text_input form={form}
        field={:virtual_icon}
        debounce="0"
        maxlength="2"
        label_text={dgettext("eyra-budget", "bank.account.icon.label")}
      />
      <.spacing value="XS" />

      <Text.title3><%= dgettext("eyra-budget", "currency.title") %></Text.title3>
      <.inputs_for :let={currency_form} field={form[:currency]}>
        <.text_input form={currency_form}
          field={:name}
          debounce="0"
          label_text={dgettext("eyra-budget", "currency.name.label")}
        />
        <Text.title6><%= dgettext("eyra-budget", "currency.label.title") %></Text.title6>
        <.spacing value="XS" />
        <.text_bundle_input form={currency_form} field={:label_bundle} />
      </.inputs_for>

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
