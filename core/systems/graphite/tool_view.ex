defmodule Systems.Graphite.ToolView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  @impl true
  def update(%{tool: tool, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(
        tool: tool,
        user: user
      )
      |> send_event(:parent, "tool_initialized")
      |> compose_child(:submission_form)
    }
  end

  @impl true
  def compose(:submission_form, %{tool: tool, user: user}) do
    %{
      module: Systems.Graphite.SubmissionForm,
      params: %{
        tool: tool,
        user: user
      }
    }
  end

  @impl true
  def handle_event("submitted", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("cancel", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "cancel_task")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-graphite", "submission.form.title") %></Text.title2>
          <.spacing value="M" />
          <.child name={:submission_form} fabric={@fabric} />
        </Area.content>
     </div>
    """
  end
end
