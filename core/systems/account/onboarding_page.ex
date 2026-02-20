defmodule Systems.Account.OnboardingPage do
  @moduledoc """
  Onboarding page for new users (especially PANL participants).
  Shows required profile steps sequentially before allowing access to the app.
  """
  use CoreWeb, :routed_live_view
  use CoreWeb.Layouts.Stripped.Composer

  import LiveNest.HTML

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Systems.Account

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    Core.Repo.preload(user, [:features, :profile])
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       current_step_index: 0,
       modal_toolbar_buttons: []
     )}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("continue", _params, socket) do
    %{
      assigns: %{
        vm: %{is_last_step: is_last_step, current_step_index: current_step_index, steps: steps}
      }
    } =
      socket

    if is_last_step do
      {:noreply, socket |> push_navigate(to: ~p"/")}
    else
      next_step = Enum.at(steps, current_step_index + 1)

      if next_step == :activate_account and activated?(socket) do
        {:noreply, socket |> push_navigate(to: ~p"/")}
      else
        {:noreply,
         socket
         |> assign(current_step_index: current_step_index + 1)
         |> update_view_model()}
      end
    end
  end

  @impl true
  def handle_event("skip", _params, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/")}
  end

  defp activated?(%{assigns: %{current_user: %{id: user_id}}}) do
    user_id
    |> Account.Public.activated?()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />

        <%= if @vm.step_view do %>
          <.element {Map.from_struct(@vm.step_view)} socket={@socket} />
        <% end %>
        <%= if @vm.step_title do %>
          <div class="flex flex-col items-center">
            <Text.title2>{@vm.step_title}</Text.title2>
            <.spacing value="S" />
            <Text.body align="text-center">{@vm.step_body}</Text.body>
          </div>
        <% end %>

        <.spacing value="L" />

        <div class="flex flex-row gap-4 justify-center">
          <Button.dynamic {@vm.continue_button} />
        </div>
      </Area.content>
    </.stripped>
    """
  end
end
