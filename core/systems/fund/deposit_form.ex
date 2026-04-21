defmodule Systems.Fund.DepositForm do
  use CoreWeb, :live_component

  import Ecto.Changeset

  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text

  alias Systems.{
    Fund
  }

  # Initial update
  @impl true
  def update(%{id: id, fund: fund, target: target}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        fund: fund,
        target: target
      )
      |> init_changeset()
      |> init_buttons()
    }
  end

  defp init_changeset(socket) do
    changeset =
      %Fund.DepositModel{}
      |> Fund.DepositModel.changeset()

    socket |> assign(changeset: changeset)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :submit},
          face: %{type: :primary, label: dgettext("eyra-fund", "deposit.submit.button")}
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> send_event(:parent, "deposit_cancelled")}
  end

  @impl true
  def handle_event(
        "submit",
        %{"deposit_model" => %{"amount" => amount, "reference" => reference}},
        socket
      ) do
    changeset = Fund.DepositModel.changeset(amount, reference)

    case apply_action(changeset, :submit) do
      {:ok, deposit} ->
        {:noreply, socket |> assign(changeset: changeset) |> make_deposit(deposit)}

      {:error, changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  defp make_deposit(%{assigns: %{fund: fund}} = socket, deposit) do
    case Fund.Public.make_test_deposit(fund, deposit) do
      {:ok, _} ->
        socket |> send_event(:parent, "deposit_saved")
        socket

      {:error, error} ->
        socket |> assign(error: error)
    end
  end

  # data(changeset, :map)
  # data(buttons, :list)
  # data(error, :any, default: nil)

  attr(:fund, :map, required: true)
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

      <Text.title2><%= dgettext("eyra-fund", "deposit.form.title") %></Text.title2>

      <.form id="deposit_form" :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.number_input form={form} field={:amount} label_text={dgettext("eyra-fund", "deposit.amount.label")} />
        <.text_input form={form} field={:reference} label_text={dgettext("eyra-fund", "deposit.reference.label")} />
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
