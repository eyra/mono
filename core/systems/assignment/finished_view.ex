defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.Assignment
  alias Systems.Pool

  def dependencies(), do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(email_submitted: false, email_error: nil)}
  end

  @impl true
  def handle_event("retry", _, socket) do
    {:noreply, socket |> publish_event(:retry)}
  end

  def handle_event(
        "submit_email",
        %{"email" => email},
        %{
          assigns: %{
            current_user: user,
            vm: %{email_capture: %{action: {:add_to_pool, pool_slug}}}
          }
        } = socket
      ) do
    case EmailSignUp.link(user, email) do
      {:ok, _user} ->
        Pool.Public.add_to_pool(pool_slug, user)
        {:noreply, socket |> assign(email_submitted: true, email_error: nil)}

      {:error, :invalid_format} ->
        {:noreply, socket |> assign(email_error: :invalid_format)}

      {:error, :already_registered} ->
        {:noreply, socket |> assign(email_error: :already_registered)}

      {:error, :disposable} ->
        {:noreply, socket |> assign(email_error: :disposable)}

      {:error, _} ->
        {:noreply, socket |> assign(email_error: :unknown)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex flex-row w-full h-full" data-testid="finished-view">
        <div class="flex-grow" />
        <div class="flex flex-col gap-4 sm:gap-8 items-center w-full h-full px-6">
          <div class="flex-grow" />
          <Text.title1 margin="" testid="finished-title"><%= @vm.title %></Text.title1>
          <div>
            <Text.body_large align="text-center" testid="finished-body">
              <%= @vm.body %>
            </Text.body_large>
            <div :if={@vm.illustration} class="flex flex-col items-center w-full pt-4" data-testid="finished-illustration">
              <img class="block w-[220px] h-[220px] object-cover" src={@vm.illustration} id="zero-todos" alt="All tasks done">
            </div>
          </div>

          <div class="flex flex-row items-center gap-6" data-testid="finished-buttons">
            <Button.dynamic :if={@vm.back_button} {@vm.back_button} testid="back-button" />
            <Button.dynamic :if={@vm.continue_button} {@vm.continue_button} testid="continue-button" />
          </div>

          <%= if @vm.email_capture do %>
            <div class="w-full max-w-sm mt-4" data-testid="email-capture-block">
              <%= if @email_submitted do %>
                <div class="text-center" data-testid="email-capture-success">
                  <Text.title3><%= @vm.email_capture.success_title %></Text.title3>
                  <Text.body_large><%= @vm.email_capture.success_body %></Text.body_large>
                </div>
              <% else %>
                <div class="text-center mb-4">
                  <Text.title3><%= @vm.email_capture.title %></Text.title3>
                  <Text.body_large><%= @vm.email_capture.body %></Text.body_large>
                </div>
                <form phx-submit="submit_email" class="flex flex-col gap-4">
                  <div>
                    <label class="block text-sm font-medium mb-1"><%= @vm.email_capture.email_label %></label>
                    <input
                      type="email"
                      name="email"
                      required
                      class="w-full border rounded-md px-3 py-2"
                      data-testid="email-capture-input"
                    />
                    <p :if={@email_error} class="text-red-500 text-sm mt-1" data-testid="email-capture-error">
                      <%= email_error_message(@email_error) %>
                    </p>
                  </div>
                  <Button.dynamic {@vm.email_capture.submit_button} testid="email-capture-submit" />
                </form>
              <% end %>
            </div>
          <% end %>

          <div class="flex-grow" />
        </div>
        <div class="flex-grow" />
      </div>
    """
  end

  defp email_error_message(:invalid_format),
    do: dgettext("eyra-assignment", "email_capture.error.invalid_format")

  defp email_error_message(:already_registered),
    do: dgettext("eyra-assignment", "email_capture.error.already_registered")

  defp email_error_message(:disposable),
    do: dgettext("eyra-assignment", "email_capture.error.disposable")

  defp email_error_message(_), do: dgettext("eyra-assignment", "email_capture.error.unknown")
end
