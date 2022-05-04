defmodule Systems.Assignment.LandingPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.UI.PlainDialog
  use CoreWeb.Layouts.Workspace.Component, :assignment

  alias Frameworks.Pixel.Text.{Title1, Title3, BodyLarge}
  alias Frameworks.Pixel.Card.Highlight
  alias Frameworks.Pixel.Wrap

  alias Core.Accounts

  alias Systems.{
    Assignment,
    NextAction
  }

  data(model, :map)
  data(task, :map)
  data(tool_view_model, :map)
  data(experiment, :map)

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Context.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    NextAction.Context.clear_next_action(user, Assignment.CheckRejection,
      key: "#{id}",
      params: %{id: id}
    )

    model = Assignment.Context.get!(id, [:crew])

    {
      :ok,
      socket
      |> assign(
        model: model,
        dialog: nil
      )
      |> observe_view_model()
      |> update_experiment_view()
      |> update_menus()
    }
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    socket
    |> update_experiment_view()
    |> update_menus()
  end

  defp update_experiment_view(
         %{
           assigns: %{
             vm: %{experiment: %{view: view, id: id, model: model}},
             experiment: experiment
           }
         } = socket
       )
       when not is_nil(experiment) do
    # send update message to existing experiment view
    send_update(view, id: id, model: model)
    socket
  end

  defp update_experiment_view(%{assigns: %{vm: %{experiment: experiment}}} = socket) do
    # initialize experiment view
    socket |> assign(experiment: experiment)
  end

  defp update_experiment_view(socket) do
    # disable experiment view
    socket |> assign(experiment: nil)
  end

  defp cancel(socket) do
    title = String.capitalize(dgettext("eyra-assignment", "cancel.confirm.title"))
    text = String.capitalize(dgettext("eyra-assignment", "cancel.confirm.text"))
    confirm_label = dgettext("eyra-assignment", "cancel.confirm.label")
    socket |> confirm("cancel", title, text, confirm_label)
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, socket |> cancel()}
  end

  @impl true
  def handle_event(
        "cancel_confirm",
        _params,
        %{assigns: %{current_user: user, model: %{id: id}}} = socket
      ) do
    Assignment.Context.cancel(id, user)

    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))}
  end

  @impl true
  def handle_event("cancel_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  @impl true
  def handle_event("inform_ok", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  def handle_info(:cancel, socket) do
    {:noreply, socket |> cancel()}
  end

  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  defp grid_cols(1), do: "grid-cols-1 sm:grid-cols-1"
  defp grid_cols(2), do: "grid-cols-1 sm:grid-cols-2"
  defp grid_cols(_), do: "grid-cols-1 sm:grid-cols-3"

  def render(assigns) do
    ~F"""
    <Workspace
      title={@vm.hero_title}
      menus={@menus}
    >
      <div :if={show_dialog?(@dialog)} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog {...@dialog} />
        </div>
      </div>

      <ContentArea>
        <MarginY id={:page_top} />
        <Title1>{@vm.title}</Title1>
        <Spacing value="L" />

        <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
          <div :for={highlight <- @vm.highlights} class="bg-grey5 rounded">
            <Highlight title={highlight.title} text={highlight.text} />
          </div>
        </div>
        <Spacing value="L" />

        <Title3>{@vm.subtitle}</Title3>
        <Spacing value="M" />

        <Wrap :if={@vm.public_id}>
          <Assignment.TicketView public_id={@vm.public_id} />
        </Wrap>
        <Spacing value="M" />

        <BodyLarge>{@vm.text}</BodyLarge>
        <Spacing value="L" />

        <Dynamic.LiveComponent :if={@experiment != nil}
          id={@experiment.id}
          module={@experiment.view}
          {...@experiment.model}
        />

      </ContentArea>
    </Workspace>
    """
  end
end
