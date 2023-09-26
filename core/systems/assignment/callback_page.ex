defmodule Systems.Assignment.CallbackPage do
  @moduledoc """
  The redirect page to complete a task
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :questionnaire

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  alias Systems.{
    Assignment
  }

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Assignment.Public.get!(id, [:crew]).crew
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    model = Assignment.Public.get!(id, [:crew])

    {
      :ok,
      socket
      |> assign(model: model)
      |> observe_view_model()
      |> activate_participant_task()
      |> update_menus()
    }
  end

  defp activate_participant_task(
         %{assigns: %{vm: %{state: :participant}, model: model, current_user: user}} = socket
       ) do
    Assignment.Public.activate_task(model, user)
    socket
  end

  defp activate_participant_task(socket), do: socket

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_event(
        "call-to-action",
        _params,
        %{
          assigns: %{
            vm: %{call_to_action: %{handle: handle}}
          }
        } = socket
      ) do
    {:noreply, handle.(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={@vm.hero_title} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title1><%= @vm.title %></Text.title1>
        <.spacing value="M" />
        <%= if @vm.state == :expired do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "task.expired.subtitle") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "task.expired.text") %></Text.body_large>
          </div>
        <% end %>

        <%= if @vm.state == :tester do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "tester.completed.subtitle") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "tester.completed.text") %></Text.body_large>
          </div>
        <% end %>

        <%= if @vm.state == :participant do %>
          <div>
            <Text.title3><%= dgettext("eyra-crew", "task.completed.title") %></Text.title3>
            <.spacing value="M" />
            <Text.body_large><%= dgettext("eyra-crew", "task.completed.message.part1") %></Text.body_large>
            <.spacing value="XS" />
            <Text.body_large><%= dgettext("eyra-crew", "task.completed.message.part2") %></Text.body_large>
          </div>
        <% end %>

        <.spacing value="L" />
        <Button.primary_live_view label={@vm.call_to_action.label} event="call-to-action" />
      </Area.content>
    </.workspace>
    """
  end
end
