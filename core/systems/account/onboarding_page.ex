defmodule Systems.Account.OnboardingPage do
  @moduledoc """
  Onboarding page for new users (especially PANL participants).
  Shows required profile steps sequentially before allowing access to the app.
  """
  use CoreWeb, :routed_live_view
  use CoreWeb.Layouts.Stripped.Composer

  import LiveNest.HTML

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Selector.Item, as: SelectorItem
  alias Frameworks.Pixel.Text
  alias Systems.Account

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})

  @policy_urls Application.compile_env(:core, :policy_urls)

  defp policy_url(key), do: @policy_urls[key]

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
       modal_toolbar_buttons: [],
       terms_accepted: false,
       terms_url: policy_url(:next_terms),
       privacy_url: policy_url(:next_privacy)
     )}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("toggle_terms", _params, %{assigns: %{terms_accepted: accepted}} = socket) do
    {:noreply, assign(socket, terms_accepted: !accepted)}
  end

  @impl true
  def handle_event(
        "continue",
        _params,
        %{assigns: %{vm: %{current_step: :terms_and_privacy}, terms_accepted: false}} = socket
      ) do
    {:noreply,
     put_flash(
       socket,
       :error,
       dgettext("eyra-account", "terms_and_privacy.onboarding.terms.required")
     )}
  end

  @impl true
  def handle_event(
        "continue",
        _params,
        %{assigns: %{vm: %{current_step: :terms_and_privacy}, current_user: user}} = socket
      ) do
    {:ok, _} =
      user
      |> Account.User.confirm_changeset()
      |> Core.Repo.update()

    {:noreply, socket |> push_navigate(to: ~p"/user/onboarding")}
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
      {:noreply, socket |> push_navigate(to: Account.UserAuth.signed_in_path(user))}
    else
      next_step = Enum.at(steps, current_step_index + 1)

      if next_step == :activate_account and activated?(socket) do
        {:noreply, socket |> push_navigate(to: Account.UserAuth.signed_in_path(user))}
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
    {:noreply, socket |> push_navigate(to: Account.UserAuth.signed_in_path(user))}
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
          <div class="flex flex-col items-center" data-testid="activate-account-view">
            <Text.title2>{@vm.step_title}</Text.title2>
            <.spacing value="S" />
            <Text.body align="text-center">{@vm.step_body}</Text.body>
          </div>
        <% end %>
        <%= if @vm.current_step == :terms_and_privacy do %>
          <.spacing value="M" />
          <div class="cursor-pointer" phx-click="toggle_terms" data-testid="terms-and-privacy-onboarding-terms">
            <SelectorItem.checkbox raw?={true} item={%{
              value: dgettext("eyra-account", "terms_and_privacy.onboarding.terms",
                terms: ~s(<a href="#{@terms_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "terms.link")}</a>),
                privacy: ~s(<a href="#{@privacy_url}" target="_blank" class="text-primary underline">#{dgettext("eyra-ui", "privacy.link")}</a>)
              ),
              active: @terms_accepted
            }} />
          </div>
        <% end %>

        <.spacing value="L" />

        <div class="flex flex-row gap-4 justify-center">
          <Button.dynamic {@vm.continue_button} testid="onboarding-continue" />
        </div>
      </Area.content>
    </.stripped>
    """
  end
end
