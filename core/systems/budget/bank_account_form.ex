defmodule Systems.Budget.BankAccountForm do
  use CoreWeb.UI.LiveComponent

  alias Ecto.Changeset
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.Text.{Title3, Title6}
  alias Frameworks.Pixel.Form.{Form, Inputs, TextInput}

  alias Systems.{
    Budget,
    Content
  }

  alias Budget.BankAccountModel, as: Model

  prop(bank_account, :any)
  prop(user, :any)
  prop(locale, :any)
  prop(target, :any)

  data(title, :string)
  data(buttons, :list)

  data(changeset, :any)
  data(validate_changeset?, :boolean)

  data(type_options, :list)
  data(type_selected, :atom)

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
    {:noreply, socket |> submit(attrs)}
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

  defp submit(%{assigns: %{bank_account: bank_account}} = socket, attrs) do
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

  def render(assigns) do
    ~F"""
    <Form
      id="bank_account_form"
      changeset={@changeset}
      submit="submit"
      change_event="change"
      target={@myself}
    >
      <Title3>{dgettext("eyra-budget", "bank.account.content.title")}</Title3>
      <TextInput
        field={:name}
        debounce="0"
        label_text={dgettext("eyra-budget", "bank.account.name.label")}
      />
      <TextInput
        field={:virtual_icon}
        debounce="0"
        maxlength="2"
        label_text={dgettext("eyra-budget", "bank.account.icon.label")}
      />
      <Spacing value="XS" />

      <Title3>{dgettext("eyra-budget", "currency.title")}</Title3>
      <Inputs field={:currency}>
        <TextInput
          field={:name}
          debounce="0"
          label_text={dgettext("eyra-budget", "currency.name.label")}
        />
        <Title6>{dgettext("eyra-budget", "currency.label.title")}</Title6>
        <Spacing value="XS" />
        <Content.TextBundleInputs field={:label_bundle} target={@myself} />
      </Inputs>

      <Spacing value="M" />
      <div class="flex flex-row gap-4">
        <DynamicButton :for={button <- @buttons} vm={button} />
      </div>
    </Form>
    """
  end
end
