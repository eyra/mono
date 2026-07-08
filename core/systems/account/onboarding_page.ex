defmodule Systems.Account.OnboardingPage do
  @moduledoc """
  Onboarding page for new users (especially PANL participants).
  Shows required profile steps sequentially before allowing access to the app.

  Honours `?return_to=/<path>` — after the last step (or a skip) the user is
  sent to that URL instead of the default signed-in landing. Used by CTAs
  that chain the user into a subsequent flow (e.g. `/pool/panl/join`).
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
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(
       current_step_index: 0,
       modal_toolbar_buttons: [],
       return_to: sanitize_return_to(Map.get(params, "return_to"))
     )}
  end

  # Same-origin paths only, so a hostile CTA can't bounce the user to an
  # external site after login.
  defp sanitize_return_to("/" <> _rest = path), do: path
  defp sanitize_return_to(_), do: nil

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  # Terms activated the user in the DB. Advance in-place instead of
  # remounting via push_navigate — a remount would reset
  # `current_step_index` to 0, and the builder (seeing an activated user)
  # would collapse the step list from [:terms_and_privacy, :profile] to
  # just [:profile], dropping the progress dots mid-flow.
  @impl true
  def consume_event(
        %{name: :terms_completed},
        %{assigns: %{vm: %{current_step_index: idx}}} = socket
      ) do
    {:stop,
     socket
     |> assign(current_step_index: idx + 1)
     |> update_view_model()}
  end

  @impl true
  def handle_event("continue", _params, socket) do
    %{
      assigns: %{
        vm: %{is_last_step: is_last_step, current_step_index: current_step_index, steps: steps},
        current_user: user
      }
    } = socket

    if is_last_step do
      {:noreply, socket |> push_navigate(to: post_onboarding_path(socket, user))}
    else
      next_step = Enum.at(steps, current_step_index + 1)

      if next_step == :activate_account and activated?(socket) do
        {:noreply, socket |> push_navigate(to: post_onboarding_path(socket, user))}
      else
        {:noreply,
         socket
         |> assign(current_step_index: current_step_index + 1)
         |> update_view_model()}
      end
    end
  end

  @impl true
  def handle_event("skip", _params, %{assigns: %{current_user: user}} = socket) do
    {:noreply, socket |> push_navigate(to: post_onboarding_path(socket, user))}
  end

  defp post_onboarding_path(%{assigns: %{return_to: return_to}}, _user)
       when is_binary(return_to),
       do: return_to

  defp post_onboarding_path(_socket, user), do: Account.UserAuth.signed_in_path(user)

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

        <Area.sheet>
          <%= if @vm.progress_dots do %>
            <div class="flex flex-row gap-2 justify-center mt-8 mb-10" data-testid="account-onboarding-progress">
              <%= for i <- 0..(@vm.progress_dots.total - 1) do %>
                <div class={"w-2 h-2 rounded-full #{if i == @vm.progress_dots.current, do: "bg-primary", else: "bg-grey4"}"}></div>
              <% end %>
            </div>
          <% end %>
          <%= if @vm.hero_title do %>
            <Text.title1>{@vm.hero_title}</Text.title1>
            <.spacing value="L" />
          <% end %>
          <%= if @vm.step_view do %>
            <.element {Map.from_struct(@vm.step_view)} socket={@socket} />
          <% end %>
          <%= if @vm.step_title do %>
            <div data-testid="activate-account-view">
              <Text.title2>{@vm.step_title}</Text.title2>
              <.spacing value="S" />
              <Text.body>{@vm.step_body}</Text.body>
            </div>
          <% end %>

          <%= if @vm.continue_button do %>
            <.spacing value="L" />
            <div class="flex flex-row gap-4 justify-start">
              <Button.dynamic {@vm.continue_button} testid="onboarding-continue" />
            </div>
          <% end %>
        </Area.sheet>
      </Area.content>
    </.stripped>
    """
  end
end
