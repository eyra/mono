defmodule Systems.Budget.BankAccountForm do
  use CoreWeb, :live_component

  alias Ecto.Changeset

  import Frameworks.Pixel.Form
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.Text

  alias Systems.{
    Budget,
    Content
  }

  import Content.TextBundleInput
  alias Budget.BankAccountModel, as: Model

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
  def update(%{id: id, bank_account: nil, user: user, locale: locale, target: target}, socket) do
    title = dgettext("eyra-budget", "bank.account.create.title")
    bank_account = %Model{}
    changeset = Model.prepare(bank_account)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        user: user,
        locale: locale,
        bank_account: bank_account,
        changeset: changeset,
        validate_changeset?: false
      )
      |> init_buttons()
    }
  end

  # Initial edit update
  @impl true
  def update(
        %{id: id, bank_account: bank_account, user: user, locale: locale, target: target},
        socket
      ) do
    title = dgettext("eyra-budget", "bank.account.edit.title")
    changeset = Model.prepare(bank_account)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        target: target,
        user: user,
        locale: locale,
        bank_account: bank_account,
        changeset: changeset,
        validate_changeset?: true
      )
      |> init_buttons()
    }
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :submit},
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
      socket |> change(attrs)
    }
  end

  @impl true
  def handle_event("submit", %{"bank_account_model" => attrs}, socket) do
    {:noreply, socket |> handle_submit(attrs)}
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: "cancel"})
    {:noreply, socket}
  end

  defp change(
         %{assigns: %{bank_account: bank_account, validate_changeset?: validate_changeset?}} =
           socket,
         attrs
       ) do
    socket
    |> apply_change(
      bank_account
      |> Model.change(attrs)
      |> Model.validate(validate_changeset?)
    )
  end

  defp apply_change(socket, changeset) do
    case Changeset.apply_action(changeset, :change) do
      {:ok, _bank_account} -> socket |> assign(changeset: changeset)
      {:error, changeset} -> socket |> assign(changeset: changeset)
    end
  end

  defp handle_submit(%{assigns: %{bank_account: bank_account}} = socket, attrs) do
    socket
    |> apply_submit(
      bank_account
      |> Model.change(attrs)
      |> Model.validate()
      |> Model.submit()
    )
  end

  defp apply_submit(%{assigns: %{target: target}} = socket, changeset) do
    case EctoHelper.upsert(changeset) do
      {:ok, _bank_account} ->
        update_target(target, %{module: __MODULE__, action: "saved"})
        socket

      {:error, changeset} ->
        socket |> assign(changeset: changeset)
    end
  end

  # data(title, :string)
  # data(buttons, :list)

  # data(changeset, :any)
  # data(validate_changeset?, :boolean)

  # data(type_options, :list)
  # data(type_selected, :atom)

  attr(:bank_account, :any)
  attr(:user, :any)
  attr(:locale, :any)
  attr(:target, :any)

  @impl true
  def render(assigns) do
    ~H"""
    <.form id="bank_account_form" :let={form} for={@changeset} phx-change="change" phx-submit="submit" phx-target={@myself} >
      <Text.title3><%= dgettext("eyra-budget", "bank.account.content.title") %></Text.title3>
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
      <.inputs form={form} :let={subform} field={:currency}>
        <.text_input form={subform}
          field={:name}
          debounce="0"
          label_text={dgettext("eyra-budget", "currency.name.label")}
        />
        <Text.title6><%= dgettext("eyra-budget", "currency.label.title") %></Text.title6>
        <.spacing value="XS" />
        <.text_bundle_input form={form} field={:label_bundle} target={@myself} />
      </.inputs>

      <.spacing value="M" />
      <div class="flex flex-row gap-4">
        <%= for button <- @buttons do %>
          <Button.dynamic {button} />
        <% end %>
      </div>
    </.form>
    """
  end
end
