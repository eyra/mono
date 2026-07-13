defmodule Systems.Pool.OnboardingPage do
  @moduledoc """
  Pool-scoped onboarding at `/pool/:slug/onboarding`.

  Reached through `Systems.Pool.Controller.join/2`, which acts as the
  gate: it resolves the slug and checks participation before forwarding
  here. This page trusts that gate — it does not re-check participation
  and does not redirect from `mount/3`. An invalid slug crashes with
  `Ecto.NoResultsError`, which Phoenix renders as 404.

  Mirrors `Systems.Account.OnboardingPage`: a builder produces the
  ordered `:steps` and the current step's `step_view` element (plus an
  optional page-level continue button); the page renders them via
  `<.element>` and progresses either via `consume_event` (for steps
  whose view publishes events, like `:join_consent`) or `handle_event`
  (for steps advanced by the continue button, like `:features`).

  Steps:

    * `:join_consent` — `Pool.JoinConsentView` publishes `:accept`.
      Accept adds the user as a participant and advances to `:features`.
      There is no decline action — users hit browser Back to exit.
    * `:features` — `Account.FeaturesView` (embedded LiveView) captures
      gender / birth year. A page-level continue button advances.
    * `:already_member` — static info block; no interaction.
  """
  use CoreWeb, :routed_live_view
  use CoreWeb.Layouts.Stripped.Composer

  import LiveNest.HTML

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Logo
  alias Frameworks.Pixel.Text
  alias Systems.Pool

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})

  @impl true
  def get_model(%{"slug" => slug}, _session, _socket) do
    Pool.Public.get_by_slug(String.to_existing_atom(slug))
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def consume_event(
        %{name: :accept},
        %{assigns: %{current_user: user, model: %Pool.Model{} = pool}} = socket
      ) do
    Pool.Public.add_participant!(pool, user)

    {:stop, socket |> advance_or_finish()}
  end

  @impl true
  def handle_event("continue", _params, socket) do
    {:noreply, socket |> advance_or_finish()}
  end

  defp advance_or_finish(
         %{assigns: %{vm: %{is_last_step: true, finish_path: finish_path}}} = socket
       ) do
    push_navigate(socket, to: finish_path)
  end

  defp advance_or_finish(%{assigns: %{vm: %{current_step_index: idx}}} = socket) do
    socket
    |> assign(current_step_index: idx + 1)
    |> update_view_model()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />

        <Area.sheet>
          <%= if @vm.progress_dots do %>
            <div class="flex flex-row gap-2 justify-center mt-8 mb-10" data-testid="pool-onboarding-progress">
              <%= for i <- 0..(@vm.progress_dots.total - 1) do %>
                <div class={"w-2 h-2 rounded-full #{if i == @vm.progress_dots.current, do: "bg-primary", else: "bg-grey4"}"}></div>
              <% end %>
            </div>
          <% end %>
          <%= if @vm.hero_title do %>
            <div class="flex flex-row items-center gap-4">
              <Text.title1 margin="">{@vm.hero_title}</Text.title1>
              <div class="flex-grow" />
              <Logo.pool name={Pool.Model.slug(@model)} variant={:wide} class="h-12" />
            </div>
            <.spacing value="L" />
          <% end %>
          <%= if @vm.step_view do %>
            <.element {Map.from_struct(@vm.step_view)} socket={@socket} />
          <% end %>
          <%= if @vm.step_title do %>
            <div data-testid="pool-already-member-view">
              <Text.title2>{@vm.step_title}</Text.title2>
              <%= if @vm.step_body do %>
                <.spacing value="S" />
                <Text.body>{@vm.step_body}</Text.body>
              <% end %>
            </div>
          <% end %>

          <%= if @vm.continue_button do %>
            <.spacing value="L" />
            <div class="flex flex-row gap-4 justify-start">
              <Button.dynamic {@vm.continue_button} testid="pool-onboarding-continue" />
            </div>
          <% end %>
        </Area.sheet>
      </Area.content>
    </.stripped>
    """
  end
end
