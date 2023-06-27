defmodule Systems.Budget.DepositForm do
  use CoreWeb, :live_component

  import Ecto.Changeset

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text

  alias Systems.{
    Budget
  }

  # Initial update
  @impl true
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

  # data(changeset, :map)
  # data(buttons, :list)
  # data(error, :any, default: nil)

  attr(:budget, :map, required: true)
  attr(:target, :any)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @error do %>
        <div class="text-button font-button text-warning leading-6">
          <%= @error %>
        </div>
        <.spacing value="XS" />
      <% end %>

      <Text.title2><%= dgettext("eyra-budget", "deposit.form.title") %></Text.title2>

      <.form id="deposit_form" :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.number_input form={form} field={:amount} label_text={dgettext("eyra-budget", "deposit.amount.label")} />
        <.text_input form={form} field={:reference} label_text={dgettext("eyra-budget", "deposit.reference.label")} />
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
