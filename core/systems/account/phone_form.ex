defmodule Systems.Account.PhoneForm do
  @moduledoc """
  In-platform modal that collects the participant's phone number for the payouts
  ("Uitbetalingen") flow.

  On submit it persists the phone, pushes it to the payment provider (so OPP no
  longer hosts a separate phone-entry page) and hands the participant off to
  OPP's iDEAL bank verification — the single remaining OPP step. The redirect
  explanation that used to live in its own confirmation modal is folded into this
  form, so the participant fills in their number and continues straight to their
  bank. Cancelling is handled by the modal chrome's close control.
  """
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form

  alias Ecto.Changeset
  alias Frameworks.Pixel.Text
  alias Systems.Account
  alias Systems.Fund

  @payouts_path "/user/account?tab=payouts"

  @impl true
  def update(%{id: id, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user,
        changeset: Account.User.phone_changeset(user, %{}),
        error: nil
      )
      |> init_buttons()
    }
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    assign(socket,
      buttons: [
        %{
          action: %{type: :submit, target: myself},
          face: %{
            type: :primary,
            label: dgettext("eyra-account", "payouts.phone.modal.confirm")
          },
          testid: "phone-modal-confirm-button"
        }
      ]
    )
  end

  @impl true
  def handle_event("change", %{"user" => attrs}, %{assigns: %{user: user}} = socket) do
    {:noreply, assign(socket, changeset: Account.User.phone_changeset(user, attrs))}
  end

  @impl true
  def handle_event("submit", %{"user" => attrs}, %{assigns: %{user: user}} = socket) do
    changeset = Account.User.phone_changeset(user, attrs)

    case Changeset.apply_action(changeset, :update) do
      {:ok, %{phone: phone}} -> {:noreply, start_verification(socket, phone)}
      {:error, changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Persist the phone, push it to OPP via the merchant API, then hand off to the
  # iDEAL bank verification (the one OPP-hosted step). A leaving redirect makes
  # dismissing the modal moot; only failures keep the form open with an error.
  # Push the phone to OPP first; persist it locally only once OPP accepted it, so
  # `user.phone` reliably reflects "OPP has it" and later visits never re-push.
  defp start_verification(%{assigns: %{user: user}} = socket, phone) do
    case Fund.Public.start_bank_verification(user, phone) do
      {:bank, url} when is_binary(url) ->
        Account.Public.update_phone(user, phone)
        redirect(socket, external: url)

      :verified ->
        Account.Public.update_phone(user, phone)
        redirect(socket, to: @payouts_path)

      {:error, _reason} ->
        assign(socket, error: dgettext("eyra-account", "payouts.phone.error.flash"))
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="phone-form">
      <Text.title2><%= dgettext("eyra-account", "payouts.phone.modal.title") %></Text.title2>
      <.spacing value="M" />
      <Text.body_large><%= dgettext("eyra-account", "payouts.phone.modal.body") %></Text.body_large>
      <.spacing value="M" />
      <.form id="phone_form" :let={form} for={@changeset} phx-change="change" phx-submit="submit" phx-target={@myself}>
        <.text_input
          form={form}
          field={:phone}
          debounce="0"
          label_text={dgettext("eyra-account", "payouts.phone.label")}
        />
        <%= if @error do %>
          <Text.body color="text-error"><%= @error %></Text.body>
          <.spacing value="XS" />
        <% end %>
        <.spacing value="S" />
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
