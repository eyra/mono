defmodule Systems.Assignment.FinishedView do
  use CoreWeb, :embedded_live_view
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.InlineBlock
  alias Frameworks.Pixel.Logo

  alias Systems.Assignment
  alias Systems.Pool

  def dependencies(), do: [:assignment_id, :current_user]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(email_error: nil)}
  end

  @impl true
  def handle_event("retry", _, socket) do
    {:noreply, socket |> publish_event(:retry)}
  end

  def handle_event("change_email", _params, socket) do
    {:noreply, socket |> assign(email_error: nil)}
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
        {:noreply, socket |> assign(email_error: nil) |> update_view_model()}

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
            <%= if @vm.email_capture do %>
              <div class="mt-8" data-testid="email-capture-block">
                <InlineBlock.inline_block
                  title={@vm.email_capture.title}
                  description={@vm.email_capture.body}
                  icon={Logo.path(:panl, {:product, :standing})}
                >
                  <%= if Map.has_key?(@vm.email_capture, :submit_button) do %>
                    <form phx-submit="submit_email" phx-change="change_email" class="flex flex-col gap-4 w-full">
                      <div>
                        <label class="field-tag(label) mt-0.5 text-title6 font-title6 leading-snug text-grey1"><%= @vm.email_capture.email_label %></label>
                        <input
                          type="email"
                          name="email"
                          required
                          class="field-input text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-44px"
                          data-testid="email-capture-input"
                        />
                        <p :if={@email_error} class="text-caption font-caption text-warning mt-1" data-testid="email-capture-error">
                          <%= email_error_message(@email_error) %>
                        </p>
                      </div>
                      <Button.submit_wide label={@vm.email_capture.submit_button.face.label} bg_color="bg-primary" testid="email-capture-submit" />
                    </form>
                  <% end %>
                </InlineBlock.inline_block>
              </div>
            <% else %>
              <div :if={@vm.illustration} class="flex flex-col items-center w-full pt-4" data-testid="finished-illustration">
                <img class="block w-[220px] h-[220px] object-cover" src={@vm.illustration} id="zero-todos" alt="All tasks done">
              </div>
            <% end %>
          </div>
          <div class="flex flex-row items-center gap-6" data-testid="finished-buttons">
            <Button.dynamic :if={@vm.back_button} {@vm.back_button} testid="back-button" />
            <Button.dynamic :if={@vm.continue_button} {@vm.continue_button} testid="continue-button" />
          </div>
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
