defmodule Systems.Assignment.LandingPage do
  @moduledoc """
  The  page for an assigned task
  """
  use CoreWeb, :live_view
  use CoreWeb.UI.PlainDialog
  use CoreWeb.Layouts.Workspace.Component, :assignment
  use Systems.Observatory.Public

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Card

  alias Core.Accounts

  alias Systems.{
    Assignment,
    NextAction
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    NextAction.Public.clear_next_action(user, Assignment.CheckRejection,
      key: "#{id}",
      params: %{id: id}
    )

    model = Assignment.Public.get!(id, [:crew])

    {
      :ok,
      socket
      |> assign(
        model: model,
        dialog: nil
      )
      |> observe_view_model()
      |> update_task_view()
      |> update_menus()
    }
  end

  def handle_view_model_updated(socket) do
    socket
    |> update_task_view()
    |> update_menus()
  end

  defp update_task_view(
         %{
           assigns: %{
             vm: %{task: %{view: view, id: id, model: model}},
             task: task
           }
         } = socket
       )
       when not is_nil(task) do
    # send update message to existing task view
    send_update(view, id: id, model: model)
    socket
  end

  defp update_task_view(%{assigns: %{vm: %{task: task}}} = socket) do
    # initialize task view
    socket |> assign(task: task)
  end

  defp update_task_view(socket) do
    # disable task view
    socket |> assign(task: nil)
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
    Assignment.Public.cancel(id, user)

    {:noreply, push_redirect(socket, to: Accounts.start_page_path(user))}
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

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={@vm.hero_title} menus={@menus}>
      <%= if show_dialog?(@dialog) do %>
        <div class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
          <div class="flex flex-row items-center justify-center w-full h-full">
            <.plain_dialog {@dialog} />
          </div>
        </div>
      <% end %>

      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title1><%= @vm.title %></Text.title1>
        <.spacing value="L" />

        <div class={"grid gap-6 sm:gap-8 #{grid_cols(Enum.count(@vm.highlights))}"}>
          <%= for highlight <- @vm.highlights do %>
            <Card.highlight {highlight} />
          <% end %>
        </div>
        <.spacing value="L" />

        <Text.title3><%= @vm.subtitle %></Text.title3>
        <.spacing value="M" />

        <%= if @vm.public_id do %>
          <.wrap>
            <Assignment.TicketView.normal public_id={@vm.public_id} />
          </.wrap>
        <% end %>
        <.spacing value="M" />

        <Text.body_large><%= @vm.text %></Text.body_large>
        <.spacing value="L" />

        <%= if @task do %>
          <.live_component
            id={@task.id}
            module={@task.view}
            {@task.model}
          />
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
