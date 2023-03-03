defmodule Systems.Budget.DepositForm do
  use CoreWeb.UI.LiveComponent

  import Ecto.Changeset

  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Form.{Form, NumberInput, TextInput}

  alias Systems.{
    Budget
  }

  prop(budget, :map, required: true)
  prop(target, :any)

  data(changeset, :map)
  data(buttons, :list)
  data(error, :any, default: nil)

  # Initial update
  def update(%{id: id, budget: budget, target: target}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        budget: budget,
        target: target
      )
      |> init_changeset()
      |> init_buttons()
    }
  end

  defp init_changeset(socket) do
    changeset =
      %Budget.DepositModel{}
      |> Budget.DepositModel.changeset()

    socket |> assign(changeset: changeset)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :submit},
          face: %{type: :primary, label: dgettext("eyra-budget", "deposit.submit.button")}
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event("cancel", _, %{assigns: %{target: target}} = socket) do
    update_target(target, %{module: __MODULE__, action: "cancel"})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit",
        %{"deposit_model" => %{"amount" => amount, "reference" => reference}},
        socket
      ) do
    changeset = Budget.DepositModel.changeset(amount, reference)

    case apply_action(changeset, :submit) do
      {:ok, deposit} ->
        {:noreply, socket |> assign(changeset: changeset) |> make_deposit(deposit)}

      {:error, changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  defp make_deposit(%{assigns: %{budget: budget, target: target}} = socket, deposit) do
    case Budget.Public.make_test_deposit(budget, deposit) do
      {:ok, _} ->
        update_target(target, %{module: __MODULE__, action: "saved"})
        socket

      {:error, error} ->
        socket |> assign(error: error)
    end
  end

  def render(assigns) do
    ~F"""
    <div>
      <div :if={@error}>
        <div class="text-button font-button text-warning leading-6">
          {@error}
        </div>
        <Spacing value="XS" />
      </div>

      <Title2>{dgettext("eyra-budget", "deposit.form.title")}</Title2>
      <Form id="deposit_form" changeset={@changeset} submit="submit" target={@myself}>
        <NumberInput field={:amount} label_text={dgettext("eyra-budget", "deposit.amount.label")} />
        <TextInput field={:reference} label_text={dgettext("eyra-budget", "deposit.reference.label")} />
        <Spacing value="M" />
        <div class="flex flex-row gap-4">
          <DynamicButton :for={button <- @buttons} vm={button} />
        </div>
      </Form>
    </div>
    """
  end
end
