defmodule Systems.Storage.EmptyConfirmationView do
  use CoreWeb, :live_component

  import Frameworks.Pixel.Form

  @impl true
  def update(%{branch_name: branch_name}, socket) do
    loading = Map.get(socket.assigns, :loading, false)
    submit_enabled = Map.get(socket.assigns, :submit_enabled, false)
    confirm_name = Map.get(socket.assigns, :confirm_name, "")

    {
      :ok,
      socket
      |> assign(
        branch_name: branch_name,
        confirm_name: confirm_name,
        loading: loading,
        submit_enabled: submit_enabled
      )
      |> update_form()
      |> update_submit_button()
    }
  end

  defp update_form(%{assigns: %{confirm_name: confirm_name}} = socket) do
    form = to_form(%{"confirm_name" => confirm_name})
    assign(socket, form: form)
  end

  defp update_submit_button(%{assigns: %{loading: loading}} = socket) do
    submit_button = %{
      action: %{
        type: :submit
      },
      face: %{
        type: :primary,
        label: dgettext("eyra-storage", "empty_confirmation_view.button"),
        bg_color: "bg-delete",
        loading: loading
      }
    }

    assign(socket, submit_button: submit_button)
  end

  def handle_event(
        "change",
        %{"confirm_name" => confirm_name},
        %{assigns: %{branch_name: branch_name}} = socket
      ) do
    submit_enabled = confirm_name == branch_name
    {:noreply, socket |> assign(confirm_name: confirm_name, submit_enabled: submit_enabled)}
  end

  def handle_event("submit", _, %{assigns: %{submit_enabled: submit_enabled}} = socket) do
    if submit_enabled do
      {
        :noreply,
        socket
        |> assign(loading: true)
        |> update_submit_button()
        |> update_form()
        |> send_event(:parent, "empty_confirmation")
      }
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
     <div id={"#{@id}_empty_confirmation_view"} phx-hook="LiveContent" data-show-errors={false}>
      <.spacing value="XXS" />
      <.form id={@id} for={@form} phx-change="change" phx-submit="submit" phx-target={@myself}>
        <div class="flex flex-col gap-8">
          <Text.title4><%= dgettext("eyra-storage", "empty_confirmation_view.title") %></Text.title4>
          <Text.body_large><%= raw(dgettext("eyra-storage", "empty_confirmation_view.body", name: @branch_name)) %></Text.body_large>
          <div class="flex flex-col gap-4">
            <.text_input form={@form} field={:confirm_name} debounce="0" placeholder={dgettext("eyra-storage", "empty_confirmation_view.placeholder")} reserve_error_space={false} />
            <.wrap>
              <Button.dynamic {@submit_button} enabled?={@submit_enabled} />
            </.wrap>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
